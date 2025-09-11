module TWENTY_PACKAGE::game {
    use std::vector;
    use std::string::{Self, String};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::table::{Self, Table};

    // Constants
    const BOARD_SIZE: u8 = 5;
    const MAX_VALUE: u64 = 2048;
    const VALUE_MULTIPLIER: u64 = 1000;
    
    // Probability constants (scaled to 10000 for precision)
    const RANDOM_TILE_PROBABILITY: u64 = 500;  // 5%
    const HEART_TILE_PROBABILITY: u64 = 300;   // 3%
    const BOMB_2_PROBABILITY: u64 = 300;       // 3%
    const BOMB_4_PROBABILITY: u64 = 200;       // 2%
    const BOMB_8_PROBABILITY: u64 = 100;       // 1%
    const REGULAR_TILE_1_PROBABILITY: u64 = 9000; // 90% of regular tiles
    const RANDOM_TILE_VALUES: vector<u64> = vector[1, 2, 4, 8, 16];

    // Error codes
    const EGameNotFound: u64 = 0;
    const EInvalidDirection: u64 = 1;
    const EGameOver: u64 = 2;
    const EInvalidMove: u64 = 3;
    const ENoEmptyCells: u64 = 4;

    // Direction enum
    public struct Direction has copy, drop, store {
        value: u8
    }

    const UP: u8 = 0;
    const DOWN: u8 = 1;
    const LEFT: u8 = 2;
    const RIGHT: u8 = 3;

    public fun direction_up(): Direction {
        Direction { value: UP }
    }

    public fun direction_down(): Direction {
        Direction { value: DOWN }
    }

    public fun direction_left(): Direction {
        Direction { value: LEFT }
    }

    public fun direction_right(): Direction {
        Direction { value: RIGHT }
    }

    // Tile types
    public struct TileType has copy, drop, store {
        value: u8
    }

    const REGULAR: u8 = 0;
    const RANDOM: u8 = 1;
    const HEART: u8 = 2;
    const BOMB: u8 = 3;

    public fun tile_type_regular(): TileType {
        TileType { value: REGULAR }
    }

    public fun tile_type_random(): TileType {
        TileType { value: RANDOM }
    }

    public fun tile_type_heart(): TileType {
        TileType { value: HEART }
    }

    public fun tile_type_bomb(): TileType {
        TileType { value: BOMB }
    }

    // Position struct
    public struct Position has copy, drop, store {
        i: u8,
        j: u8
    }

    public fun position(i: u8, j: u8): Position {
        assert!(i < BOARD_SIZE, EInvalidMove);
        assert!(j < BOARD_SIZE, EInvalidMove);
        Position { i, j }
    }

    // Tile struct
    public struct Tile has copy, drop, store {
        value: u64,
        tile_type: TileType,
        is_bomb: bool,
        is_random: bool,
        is_heart: bool
    }

    public fun tile(value: u64, tile_type: TileType): Tile {
        Tile {
            value,
            tile_type,
            is_bomb: tile_type.value == BOMB,
            is_random: tile_type.value == RANDOM,
            is_heart: tile_type.value == HEART
        }
    }

    public fun tile_value(tile: &Tile): u64 {
        tile.value
    }

    public fun tile_type(tile: &Tile): TileType {
        tile.tile_type
    }

    public fun is_bomb(tile: &Tile): bool {
        tile.is_bomb
    }

    public fun is_random(tile: &Tile): bool {
        tile.is_random
    }

    public fun is_heart(tile: &Tile): bool {
        tile.is_heart
    }

    // Game state struct
    public struct GameState has store {
        id: String,
        board: Table<Position, Tile>,
        score: u64,
        moves: u64,
        is_game_over: bool,
        created_at: u64
    }

    // Game object
    public struct Game has key {
        id: UID,
        state: GameState,
        owner: address
    }

    // Events
    public struct GameCreated has copy, drop {
        game_id: String,
        owner: address
    }

    public struct TileAdded has copy, drop {
        game_id: String,
        position: Position,
        tile: Tile
    }

    public struct MoveExecuted has copy, drop {
        game_id: String,
        direction: Direction,
        moved: bool,
        score_gained: u64
    }

    public struct BombExploded has copy, drop {
        game_id: String,
        center: Position,
        affected_positions: vector<Position>
    }

    public struct GameOver has copy, drop {
        game_id: String,
        reason: String
    }

    public entry fun new_game_entry(gameId: String, recipient: address, ctx: &mut TxContext) {
        let game = new_game(gameId, ctx);
        transfer_game(game, recipient, ctx);
    }

    public entry fun add_new_tile_entry(
        game: &mut Game,
        random_index: u64,
        random_value: u64, 
        bomb_random: u64,
        bomb_cumulative : u64,
        regular_random: u64,
        ctx: &mut TxContext) {
        add_new_tile(game, random_index, random_value, bomb_random, bomb_cumulative, regular_random, ctx);
    }

    public entry fun execute_move_entry(
        game: &mut Game, 
        direction: u8,
        ctx: &mut TxContext) {

        let direction = if (direction == UP) {
            direction_up()
        } else if (direction == DOWN) {
            direction_down()
        } else if (direction == LEFT) {
            direction_left()
        } else if (direction == RIGHT) {
            direction_right()
        } else {
            abort EInvalidDirection
        };
        execute_move(game, direction, ctx);
    }

    public entry fun click_random_tile_entry(
    game: &mut Game,
    random_index: u64,
    row: u8,
    col: u8,
    ctx: &mut TxContext) {
        replace_random_tile_with_value(game, random_index, row, col, ctx);
    }

    // Game creation
    public fun new_game(gameId : String, ctx: &mut TxContext): Game {
        let game_id = gameId;
        let id = object::new(ctx);
        
        let state = GameState {
            id: game_id,
            board: table::new<Position, Tile>(ctx),
            score: 0,
            moves: 0,
            is_game_over: false,
            created_at: tx_context::epoch_timestamp_ms(ctx)
        };

        let game = Game {
            id,
            state,
            owner: tx_context::sender(ctx)
        };

        // event::emit(GameCreated {
        //     game_id,
        //     owner: tx_context::sender(ctx)
        // });

        game
    }

    // Add new tile to the board
    public fun add_new_tile(
        game: &mut Game,
        random_index: u64,
        random_value: u64, 
        bomb_random: u64,
        bomb_cumulative : u64,
        regular_random: u64,
        ctx: &mut TxContext) {
        assert!(!game.state.is_game_over, EGameOver);
        
        let mut empty_positions = get_empty_positions(&game.state);

        if(vector::length(&empty_positions) == 0){
            game.state.is_game_over = true;
            event::emit(GameOver {
                game_id: game.state.id,
                reason: string::utf8(b"No empty cells to add new tile")
            });
            return;
        };
        
        let position = *vector::borrow(&empty_positions, random_index);

        let tile = generate_random_tile(
            random_value, 
            bomb_random, 
            bomb_cumulative, 
            regular_random, 
            ctx);

        table::add(&mut game.state.board, position, tile);
        
        event::emit(TileAdded {
            game_id: game.state.id,
            position,
            tile
        });

         // 先清空向量
        while (!vector::is_empty(&empty_positions)) {
            vector::pop_back(&mut empty_positions);
        };
        // 然後銷毀空向量
        vector::destroy_empty(empty_positions);
    }

    // Generate random tile based on probability system
    fun generate_random_tile(
        random_value: u64, 
        bomb_random: u64,
        bomb_cumulative : u64,
        regular_random: u64, 
        ctx: &mut TxContext): Tile {

        // Tier 1: Special tile selection
        if (random_value < RANDOM_TILE_PROBABILITY) {
            return tile(1, tile_type_random())
        };
        
        if (random_value < RANDOM_TILE_PROBABILITY + HEART_TILE_PROBABILITY) {
            return tile(1, tile_type_heart())
        };
        
        // Tier 2: Bomb tile selection
        
        if (bomb_random < BOMB_2_PROBABILITY) {
            return tile(2, tile_type_bomb())
        };
        
        if (bomb_random < bomb_cumulative + BOMB_2_PROBABILITY + BOMB_4_PROBABILITY) {
            return tile(4, tile_type_bomb())
        };
        
        // bomb_cumulative = bomb_cumulative + BOMB_4_PROBABILITY;
        if (bomb_random < bomb_cumulative + BOMB_2_PROBABILITY + BOMB_4_PROBABILITY + BOMB_8_PROBABILITY) {
            return tile(8, tile_type_bomb())
        };
        
        // Tier 3: Regular tile
        if (regular_random < REGULAR_TILE_1_PROBABILITY) {
            return tile(1, tile_type_regular())
        } else {
            return tile(2, tile_type_regular())
        }
    }

    // Get all empty positions on the board
    fun get_empty_positions(state: &GameState): vector<Position> {
        let mut empty_positions = vector::empty<Position>();
        let mut i = 0;
        
        while (i < BOARD_SIZE) {
            let mut j = 0;
            while (j < BOARD_SIZE) {
                let pos = position(i, j);
                if (!table::contains(&state.board, pos)) {
                    vector::push_back(&mut empty_positions, pos);
                };
                j = j + 1;
            };
            i = i + 1;
        };
        
        empty_positions
    }

    fun get_random_tile_values(): vector<u64> {
        let mut values = vector::empty<u64>();
        vector::push_back(&mut values, 1);
        vector::push_back(&mut values, 2);
        vector::push_back(&mut values, 4);
        vector::push_back(&mut values, 8);
        vector::push_back(&mut values, 16);
        values
    }

    // Get random tile value (for external use)
    /// 點擊隨機方塊後替換為新的隨機值
    public fun replace_random_tile_with_value(
        game: &mut Game,
        random_index: u64,
        row: u8,
        col: u8,
        ctx: &mut TxContext
    ) {
        let random_tile_values = get_random_tile_values();

        // 檢查遊戲是否結束
        assert!(!game.state.is_game_over, EGameOver);
        
        // 檢查隨機索引是否有效
        assert!(random_index < vector::length(&random_tile_values), 1); // 假設錯誤碼 1
        
        // 從預定義的隨機值中獲取新值
        let random_value = *vector::borrow(&random_tile_values, random_index);
        
        let pos = position(row, col);
        
        // 檢查位置是否存在方塊
        assert!(table::contains(&game.state.board, pos), 2); // 假設錯誤碼 2
        
        // 獲取舊方塊並檢查是否為隨機方塊
        let old_tile = table::remove(&mut game.state.board, pos);
        assert!(is_random(&old_tile), 3); // 確保是隨機方塊，假設錯誤碼 3
        
        // 創建新的普通方塊（替換隨機方塊）
        let new_tile = tile(random_value, tile_type_regular());
        
        // 添加新方塊到相同位置
        table::add(&mut game.state.board, pos, new_tile);
        
        // 發出事件通知方塊被替換
        event::emit(TileAdded {
            game_id: game.state.id,
            position: pos,
            tile: new_tile
        });
    }

    // Execute a move in the specified direction
    public fun execute_move(
        game: &mut Game, 
        direction: Direction,
        ctx: &mut TxContext) {
        assert!(!game.state.is_game_over, EGameOver);
        
        let (moved, explosions) = if (direction.value == UP) {
            move_up(game, ctx)
        } else if (direction.value == DOWN) {
            move_down(game, ctx)
        } else if (direction.value == LEFT) {
            move_left(game, ctx)
        } else if (direction.value == RIGHT) {
            move_right(game, ctx)
        } else {
            abort EInvalidDirection
        };
        
        if (moved) {
            game.state.moves = game.state.moves + 1;
            
            // Process explosions
            let mut i = 0;
            while (i < vector::length(&explosions)) {
                let explosion_pos = *vector::borrow(&explosions, i);
                explode_at(game, explosion_pos);
                i = i + 1;
            };
        };
        
        event::emit(MoveExecuted {
            game_id: game.state.id,
            direction,
            moved,
            score_gained: 0 // TODO: Calculate score
        });
        
        vector::destroy!(explosions, |_pos| ());
    }

    public fun move_up(game: &mut Game, ctx: &mut TxContext): (bool, vector<Position>) {
        let mut moved = false;
        let mut explosions = vector::empty<Position>();
        let mut j = 0;
        
        while (j < BOARD_SIZE) {
            let column = get_column(&game.state, j);
            let (new_column, column_moved, column_explosions) = process_line_with_bombs(game, column, false);
            
            if (column_moved) {
                moved = true;
            };
            
            // Add explosions with correct row indices
            let mut i = 0;
            while (i < vector::length(&column_explosions)) {
                let explosion_index = *vector::borrow(&column_explosions, i);
                vector::push_back(&mut explosions, position(explosion_index as u8, j));
                i = i + 1;
            };
            
            set_column(game, j, new_column);
            j = j + 1;
        };
        
        (moved, explosions)
    }

    // Move down
    fun move_down(game: &mut Game, ctx: &mut TxContext): (bool, vector<Position>) {
        let mut moved = false;
        let mut explosions = vector::empty<Position>();
        let mut j = 0;

        while (j < BOARD_SIZE) {
            let column = get_column(&game.state, j);
            let (new_column, column_moved, column_explosions) = process_line_with_bombs(game, column, true);
            
            if (column_moved) {
                moved = true;
            };
            
            // Add explosions with correct row indices (reversed)
            let mut i = 0;
            while (i < vector::length(&column_explosions)) {
                let explosion_index = *vector::borrow(&column_explosions, i);
                vector::push_back(&mut explosions, position(BOARD_SIZE - 1 - (explosion_index as u8), j));
                i = i + 1;
            };
            
            set_column(game, j, new_column);
            j = j + 1;
        };
        
        (moved, explosions)
    }

    // Move left
    fun move_left(game: &mut Game, ctx: &mut TxContext): (bool, vector<Position>) {
        let mut moved = false;
        let mut explosions = vector::empty<Position>();
        let mut i = 0;
        
        while (i < BOARD_SIZE) {
            let row = get_row(&game.state, i);
            let (new_row, row_moved, row_explosions) = process_line_with_bombs(game, row, false);
            
            if (row_moved) {
                moved = true;
            };
            
            // Add explosions with correct column indices
            let mut j = 0;
            while (j < vector::length(&row_explosions)) {
                let explosion_index = *vector::borrow(&row_explosions, j);
                vector::push_back(&mut explosions, position(i, explosion_index as u8));
                j = j + 1;
            };
            
            set_row(game, i, new_row);
            i = i + 1;
        };
        
        (moved, explosions)
    }

    // Move right
    fun move_right(game: &mut Game, ctx: &mut TxContext): (bool, vector<Position>) {
        let mut moved = false;
        let mut explosions = vector::empty<Position>();
        let mut i = 0;

        while (i < BOARD_SIZE) {
            let row = get_row(&game.state, i);
            let (new_row, row_moved, row_explosions) = process_line_with_bombs(game, row, true);
            
            if (row_moved) {
                moved = true;
            };
            
            // Add explosions with correct column indices (reversed)
            let mut j = 0;
            while (j < vector::length(&row_explosions)) {
                let explosion_index = *vector::borrow(&row_explosions, j);
                // For right move, explosion_index is the position in the processed row
                // We need to map it to the actual board position
                vector::push_back(&mut explosions, position(i, explosion_index as u8));
                j = j + 1;
            };
            
            set_row(game, i, new_row);
            i = i + 1;
        };
        
        (moved, explosions)
    }

    // Get row from board
    fun get_row(state: &GameState, row_index: u8): vector<Tile> {
        let mut row = vector::empty<Tile>();
        let mut j = 0;
        
        while (j < BOARD_SIZE) {
            let pos = position(row_index, j);
            if (table::contains(&state.board, pos)) {
                let tile = table::borrow(&state.board, pos);
                vector::push_back(&mut row, *tile);
            } else {
                // 如果位置沒有 tile，添加空的 tile
                vector::push_back(&mut row, tile(0, tile_type_regular()));
            };
            j = j + 1;
        };
        
        row
    }

    // Get column from board
    fun get_column(state: &GameState, col_index: u8): vector<Tile> {
        let mut column = vector::empty<Tile>();
        let mut i = 0;
        
        while (i < BOARD_SIZE) {
            let pos = position(i, col_index);
            if (table::contains(&state.board, pos)) {
                let tile = table::borrow(&state.board, pos);
                vector::push_back(&mut column, *tile);
            } else {
                // 如果位置沒有 tile，添加空的 tile
                vector::push_back(&mut column, tile(0, tile_type_regular()));
            };
            i = i + 1;
        };
        
        column
    }

    // Process line with bomb handling
    fun process_line_with_bombs(game: &mut Game,line: vector<Tile>, reverse: bool): (vector<Tile>, bool, vector<u64>) {
        let mut line = line;
        if (reverse) {
            vector::reverse(&mut line);
        };
        
        let mut explosions = vector::empty<u64>();
        let mut moved = false;
        let mut i = 0;
        let line_length = vector::length(&line);
        
        // If line has less than 2 tiles, no merging is possible
        if (line_length < 2) {
            // Fill empty spaces if needed
            while (vector::length(&line) < (BOARD_SIZE as u64)) {
                vector::push_back(&mut line, tile(0, tile_type_regular()));
            };
            
            if (reverse) {
                vector::reverse(&mut line);
            };
            
            return (line, moved, explosions)
        };
        
        // First, move all non-zero tiles to the front (left)
        let mut non_zero_tiles = vector::empty<Tile>();
        let mut i = 0;
        while (i < vector::length(&line)) {
            let tile = *vector::borrow(&line, i);
            if (tile_value(&tile) > 0) {
                vector::push_back(&mut non_zero_tiles, tile);
            };
            i = i + 1;
        };
        
        // Replace the line with non-zero tiles followed by zeros
        line = non_zero_tiles;
        while (vector::length(&line) < (BOARD_SIZE as u64)) {
            vector::push_back(&mut line, tile(0, tile_type_regular()));
        };
        
        // Now merge adjacent tiles with same value (each tile can only merge once per move)
        i = 0;
        while (i < vector::length(&line) - 1) {
            let tile1 = *vector::borrow(&line, i);
            let tile2 = *vector::borrow(&line, i + 1);
            
            // Heart tiles cannot merge
            if (is_heart(&tile1) || is_heart(&tile2)) {
                i = i + 1;
                continue
            };
            
            // Merge condition: same value, not random, not exceeding max value, and not empty tiles
            if (tile_value(&tile1) == tile_value(&tile2) && 
                tile_value(&tile1) > 0 &&
                tile_value(&tile1) < MAX_VALUE && 
                !is_random(&tile1) && !is_random(&tile2)) {
                
                // Check for bomb explosion
                if (is_bomb(&tile1) || is_bomb(&tile2)) {
                    vector::push_back(&mut explosions, i);
                };
                
                // Merge tiles
                let new_value = tile_value(&tile1) + tile_value(&tile2);
                let merged_tile = tile(new_value, tile_type_regular());

                game.state.score = game.state.score + new_value * VALUE_MULTIPLIER;
                
                // Remove both tiles and insert merged tile
                vector::remove(&mut line, i + 1);
                vector::remove(&mut line, i);
                vector::insert(&mut line, merged_tile, i);
                
                moved = true;
                // Skip the next tile since it was already merged
                i = i + 1;
            } else {
                i = i + 1;
            };
        };
    
        // Fill empty spaces
        while (vector::length(&line) < (BOARD_SIZE as u64)) {
            vector::push_back(&mut line, tile(0, tile_type_regular()));
        };
        
        if (reverse) {
            vector::reverse(&mut line);
            // Reverse explosion positions
            let mut i = 0;
            while (i < vector::length(&explosions)) {
                let explosion_index = *vector::borrow(&explosions, i);
                let new_index = (BOARD_SIZE as u64) - 1 - explosion_index;
                *vector::borrow_mut(&mut explosions, i) = new_index;
                i = i + 1;
            };
        };
        
        (line, moved, explosions)
    }

    // Set row on board
    fun set_row(game: &mut Game, row_index: u8, new_row: vector<Tile>) {
        let mut j: u8 = 0;
        let mut row = new_row;

        while (j < BOARD_SIZE) {
            let pos = position(row_index, j);

            if (table::contains(&game.state.board, pos)) {
                table::remove(&mut game.state.board, pos);
            };
            
            if (!vector::is_empty(&row)) {
                let tile = vector::remove(&mut row, 0);
                if (tile_value(&tile) > 0) {
                    table::add(&mut game.state.board, pos, tile);
                };
            };

            j = j + 1;
        };
        
        vector::destroy_empty(row);
    }

    // Set column on board
    fun set_column(game: &mut Game, col_index: u8, new_column: vector<Tile>) {
        let mut i: u8 = 0;
        let mut column = new_column;
        
        while (i < BOARD_SIZE) {
            let pos = position(i, col_index);
            
            // 移除現有的 tile（如果存在）
            if (table::contains(&game.state.board, pos)) {
                table::remove(&mut game.state.board, pos);
            };
            
            // 添加新的 tile（如果存在且有效）
            if (!vector::is_empty(&column)) {
                let tile = vector::remove(&mut column, 0);
                if (tile_value(&tile) > 0) {
                    table::add(&mut game.state.board, pos, tile);
                };
            };
            
            i = i + 1;
        };
        
        vector::destroy_empty(column);
    }

    // Explode at position
    fun explode_at(game: &mut Game, center: Position) {
        let mut affected_positions = vector::empty<Position>();
        
        // Cross-shaped explosion pattern
        let mut i = 0;
        while (i < BOARD_SIZE) {
            let mut j = 0;
            while (j < BOARD_SIZE) {
                let pos = position(i, j);
                if ((i == center.i && j == center.j) ||
                    (i == center.i && (j == center.j + 1 || (center.j > 0 && j == center.j - 1))) ||
                    (j == center.j && (i == center.i + 1 || (center.i > 0 && i == center.i - 1)))) {
                    vector::push_back(&mut affected_positions, pos);
                };
                j = j + 1;
            };
            i = i + 1;
        };
        
        // Clear affected tiles
        let mut i = 0;
        while (i < vector::length(&affected_positions)) {
            let pos = *vector::borrow(&affected_positions, i);
            if (table::contains(&game.state.board, pos)) {
                let tile = table::remove(&mut game.state.board, pos);
                
                // Check if heart tile was destroyed
                if (is_heart(&tile)) {
                    game.state.is_game_over = true;
                    event::emit(GameOver {
                        game_id: game.state.id,
                        reason: string::utf8(b"Heart tile destroyed by explosion")
                    });
                    // Don't destroy affected_positions here, let it be destroyed at the end
                };
            };
            i = i + 1;
        };
        
        event::emit(BombExploded {
            game_id: game.state.id,
            center,
            affected_positions
        });
        
        // affected_positions is consumed by the event emission, no need to destroy
    }

    // Get game state
    public fun get_game_state(game: &Game): &GameState {
        &game.state
    }

    // Check if game is over
    public fun is_game_over(game: &Game): bool {
        game.state.is_game_over
    }

    // Get game score
    public fun get_score(game: &Game): u64 {
        game.state.score
    }

    // Get number of moves
    public fun get_moves(game: &Game): u64 {
        game.state.moves
    }

     // 在 game 模組中添加這些函數
    public fun get_board(game: &Game): &Table<Position, Tile> {
        &game.state.board
    }

    public fun get_board_mut(game: &mut Game): &mut Table<Position, Tile> {
        &mut game.state.board
    }

    public fun get_tile_value(tile: &Tile): u64 {
        tile.value
    }

    public fun get_tile_type(tile: &Tile): u8 {
        if (tile.is_bomb) {
            3
        } else if (tile.is_heart) {
            2
        } else if (tile.is_random) {
            1
        } else {
            0
        }
    }

    public fun get_state(game: &Game): &GameState {
        &game.state
    }

    public fun get_state_mut(game: &mut Game): &mut GameState {
        &mut game.state
    }

    // Transfer game ownership
    public fun transfer_game(game: Game, recipient: address, ctx: &mut TxContext) {
        transfer::transfer(game, recipient)
    }

    // Destroy game (only owner can do this)
    // public fun destroy_game(game: Game) {
    //     let Game { id, state, owner: _ } = game;
    //     let GameState { id: _, board, score: _, moves: _, is_game_over: _, created_at: _ } = state;
        
    //     // Clean up the board table
    //     table::drop_unchecked(board);
    //     object::delete(id);
    // }
}
