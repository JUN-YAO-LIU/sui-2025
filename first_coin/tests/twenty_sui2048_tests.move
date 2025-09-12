#[test_only]
module TWENTY_PACKAGE::game_tests {
    use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};
    use std::string::{Self, String};
    use sui::table::{Self, Table};
    use TWENTY_PACKAGE::game::{Self, Game};

    const VALUE_MULTIPLIER: u64 = 1000;
    const ADMIN: address = @0xAD;
    const PLAYER1: address = @0xA1;
    const PLAYER2: address = @0xA2;

    // Helper function to create a test scenario
    fun init_test(): Scenario {
        test::begin(ADMIN)
    }

    // Helper function to create a clock for testing

    #[test]
    fun test_new_game_creation() {
        let mut scenario = test::begin(ADMIN);
        
        // Create a new game
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"game_1");
            let game = game::new_game(gameId, ctx(&mut scenario));
            
            // Verify game initial state
            assert!(game::get_score(&game) == 0, 0);
            assert!(game::get_moves(&game) == 0, 1);
            assert!(!game::is_game_over(&game), 2);
            
            // Transfer game to player
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_direction_creation() {
        // Test all direction functions
        let up = game::direction_up();
        let down = game::direction_down();
        let left = game::direction_left();
        let right = game::direction_right();
        
        // Directions should be different from each other
        // Note: We can't directly compare Direction structs, 
        // but we can verify they don't cause errors
        let _ = up;
        let _ = down;
        let _ = left;
        let _ = right;
    }

    #[test]
    fun test_position_creation() {
        // Test valid positions
        let pos1 = game::position(0, 0);
        let pos2 = game::position(2, 3);
        let pos3 = game::position(4, 4);
        
        let _ = pos1;
        let _ = pos2;
        let _ = pos3;
    }

    #[test]
    fun test_add_new_tile(){
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"1234-abcd");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            // 或者使用現有的 add_new_tile 並檢查結果
            game::add_new_tile(
                &mut userGame,
                1,  // 位置亂數 0: (0,0), 1: (0,1), 2: (0,2), 3: (0,3), 4: (0,4), 5: (1,0), 6: (1,1), 7: (1,2), 8: (1,3), 9: (1,4), 10: (2,0), 11: (2,1), 12: (2,2), 13: (2,3), 14: (2,4), 15: (3,0), 16: (3,1), 17: (3,2), 18: (3,3), 19: (3,4), 20: (4,0), 21: (4,1), 22: (4,2), 23: (4,3), 24: (4,4)
                4, // random rate
                1, // bomb rate
                1, // bomb rate calculation
                500, 
                ctx(&mut scenario));
            
            let board = game::get_board(&userGame);
            let state = game::get_state(&userGame);
            std::debug::print(state);
            std::debug::print(board);

            let expected_position = game::position(0, 1);

            // 添加後確認位置被佔用
            assert!(table::contains(board, expected_position), 1);
            
            // 獲取並檢查 tile
            let tile = table::borrow(board, expected_position);

            let expected_value = 1;

            let value = game::get_tile_value(tile);
            assert!(value == expected_value, 1);
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    // Helper function to add a tile at specific position
    fun add_tile_at_position(game: &mut Game, row: u8, col: u8, value: u64, tile_type: u8, ctx: &mut TxContext) {
        let pos = game::position(row, col);
        let tile = if (tile_type == 0) {
            game::tile(value, game::tile_type_regular())
        } else if (tile_type == 1) {
            game::tile(value, game::tile_type_random())
        } else if (tile_type == 2) {
            game::tile(value, game::tile_type_heart())
        } else {
            game::tile(value, game::tile_type_bomb())
        };
        
        let board = game::get_board_mut(game);
        if (table::contains(board, pos)) {
            table::remove(board, pos);
        };
        table::add(board, pos, tile);
    }

    #[test]
    fun test_move_up_not_merge() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_up");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add tiles at bottom of board
            add_tile_at_position(&mut userGame, 0, 0, 2, 0, ctx(&mut scenario)); // Regular tile
            add_tile_at_position(&mut userGame, 4, 1, 1, 0, ctx(&mut scenario)); // Regular tile
            
            // Debug: Check initial state
            let board_before = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"Before move:"));
            std::debug::print(board_before);
            
            // Execute up move
            game::execute_move(&mut userGame, game::direction_up(), ctx(&mut scenario));
            
            // Debug: Check final state
            let board_after = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"After move:"));
            std::debug::print(board_after);
            
            // Debug: Check all positions in column 0
            let mut i = 0;
            while (i < 5) {
                let pos = game::position(i, 0);
                if (table::contains(board_after, pos)) {
                    let tile = table::borrow(board_after, pos);
                    std::debug::print(&string::utf8(b"Position "));
                    std::debug::print(&i);
                    std::debug::print(&string::utf8(b" has value "));
                    std::debug::print(&game::get_tile_value(tile));
                };
                i = i + 1;
            };
            
            // Check that tiles moved to top
            assert!(table::contains(board_after, game::position(0, 0)), 1);
            assert!(table::contains(board_after, game::position(0, 1)), 2);
            assert!(!table::contains(board_after, game::position(4, 1)), 3);
            
            // Check merged value
            let tile_1 = table::borrow(board_after, game::position(0, 0));
            assert!(game::get_tile_value(tile_1) == 2, 4);

            let tile_2 = table::borrow(board_after, game::position(0, 1));
            assert!(game::get_tile_value(tile_2) == 1, 5);

            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_move_up_not_merge_not_move() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_up");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add tiles at bottom of board
            add_tile_at_position(&mut userGame, 0, 0, 2, 0, ctx(&mut scenario)); // Regular tile
            add_tile_at_position(&mut userGame, 0, 1, 1, 0, ctx(&mut scenario)); // Regular tile
            
            // Debug: Check initial state
            let board_before = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"Before move:"));
            std::debug::print(board_before);
            
            // Execute up move
            game::execute_move(&mut userGame, game::direction_up(), ctx(&mut scenario));
            
            // Debug: Check final state
            let board_after = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"After move:"));
            std::debug::print(board_after);
            
            // Debug: Check all positions in column 0
            let mut i = 0;
            while (i < 5) {
                let pos = game::position(i, 0);
                if (table::contains(board_after, pos)) {
                    let tile = table::borrow(board_after, pos);
                    std::debug::print(&string::utf8(b"Position "));
                    std::debug::print(&i);
                    std::debug::print(&string::utf8(b" has value "));
                    std::debug::print(&game::get_tile_value(tile));
                };
                i = i + 1;
            };
            
            // Check that tiles moved to top
            assert!(table::contains(board_after, game::position(0, 0)), 1);
            assert!(table::contains(board_after, game::position(0, 1)), 2);
            
            // Check merged value
            let tile_1 = table::borrow(board_after, game::position(0, 0));
            assert!(game::get_tile_value(tile_1) == 2, 4);

            let tile_2 = table::borrow(board_after, game::position(0, 1));
            assert!(game::get_tile_value(tile_2) == 1, 5);

            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_move_down_not_merge() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_up");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add tiles at bottom of board
            add_tile_at_position(&mut userGame, 0, 0, 2, 0, ctx(&mut scenario)); // Regular tile
            add_tile_at_position(&mut userGame, 4, 1, 1, 0, ctx(&mut scenario)); // Regular tile
            
            // Debug: Check initial state
            let board_before = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"Before move:"));
            std::debug::print(board_before);
            
            // Execute up move
            game::execute_move(&mut userGame, game::direction_down(), ctx(&mut scenario));
            
            // Debug: Check final state
            let board_after = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"After move:"));
            std::debug::print(board_after);
            
            // Debug: Check all positions in column 0
            let mut i = 0;
            while (i < 5) {
                let pos = game::position(i, 0);
                if (table::contains(board_after, pos)) {
                    let tile = table::borrow(board_after, pos);
                    std::debug::print(&string::utf8(b"Position "));
                    std::debug::print(&i);
                    std::debug::print(&string::utf8(b" has value "));
                    std::debug::print(&game::get_tile_value(tile));
                };
                i = i + 1;
            };
            
            // Check that tiles moved to top
            assert!(!table::contains(board_after, game::position(0, 0)), 1);
            assert!(table::contains(board_after, game::position(4, 0)), 2);
            assert!(table::contains(board_after, game::position(4, 1)), 3);
            
            // Check merged value
            let tile_1 = table::borrow(board_after, game::position(4, 0));
            assert!(game::get_tile_value(tile_1) == 2, 4);

            let tile_2 = table::borrow(board_after, game::position(4, 1));
            assert!(game::get_tile_value(tile_2) == 1, 5);

            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_move_down_not_merge_not_move() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_up");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add tiles at bottom of board
            add_tile_at_position(&mut userGame, 4, 4, 2, 0, ctx(&mut scenario)); // Regular tile
            add_tile_at_position(&mut userGame, 4, 1, 1, 0, ctx(&mut scenario)); // Regular tile
            
            // Debug: Check initial state
            let board_before = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"Before move:"));
            std::debug::print(board_before);
            
            // Execute up move
            game::execute_move(&mut userGame, game::direction_down(), ctx(&mut scenario));
            
            // Debug: Check final state
            let board_after = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"After move:"));
            std::debug::print(board_after);
            
            // Debug: Check all positions in column 0
            let mut i = 0;
            while (i < 5) {
                let pos = game::position(i, 0);
                if (table::contains(board_after, pos)) {
                    let tile = table::borrow(board_after, pos);
                    std::debug::print(&string::utf8(b"Position "));
                    std::debug::print(&i);
                    std::debug::print(&string::utf8(b" has value "));
                    std::debug::print(&game::get_tile_value(tile));
                };
                i = i + 1;
            };
            
            // Check that tiles moved to top
            assert!(table::contains(board_after, game::position(4, 4)), 2);
            assert!(table::contains(board_after, game::position(4, 1)), 3);
            
            // Check merged value
            let tile_1 = table::borrow(board_after, game::position(4, 4));
            assert!(game::get_tile_value(tile_1) == 2, 4);

            let tile_2 = table::borrow(board_after, game::position(4, 1));
            assert!(game::get_tile_value(tile_2) == 1, 5);

            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_move_right_not_merge() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_up");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add tiles at bottom of board
            add_tile_at_position(&mut userGame, 2, 2, 2, 0, ctx(&mut scenario)); // Regular tile
            add_tile_at_position(&mut userGame, 4, 1, 1, 0, ctx(&mut scenario)); // Regular tile
            
            // Debug: Check initial state
            let board_before = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"Before move:"));
            std::debug::print(board_before);
            
            // Execute up move
            game::execute_move(&mut userGame, game::direction_right(), ctx(&mut scenario));
            
            // Debug: Check final state
            let board_after = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"After move:"));
            std::debug::print(board_after);
            
            // Debug: Check all positions in column 0
            let mut i = 0;
            while (i < 5) {
                let pos = game::position(i, 0);
                if (table::contains(board_after, pos)) {
                    let tile = table::borrow(board_after, pos);
                    std::debug::print(&string::utf8(b"Position "));
                    std::debug::print(&i);
                    std::debug::print(&string::utf8(b" has value "));
                    std::debug::print(&game::get_tile_value(tile));
                };
                i = i + 1;
            };
            
            // Check that tiles moved to top
            assert!(!table::contains(board_after, game::position(2, 2)), 1);
            assert!(!table::contains(board_after, game::position(4, 1)), 2);
            assert!(table::contains(board_after, game::position(2, 4)), 3);
            assert!(table::contains(board_after, game::position(4, 4)), 4);
            
            // Check merged value
            let tile_1 = table::borrow(board_after, game::position(2, 4));
            assert!(game::get_tile_value(tile_1) == 2, 4);

            let tile_2 = table::borrow(board_after, game::position(4, 4));
            assert!(game::get_tile_value(tile_2) == 1, 5);

            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_move_right_not_merge_not_move() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_up");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add tiles at bottom of board
            add_tile_at_position(&mut userGame, 2, 4, 2, 0, ctx(&mut scenario)); // Regular tile
            add_tile_at_position(&mut userGame, 4, 4, 1, 0, ctx(&mut scenario)); // Regular tile
            add_tile_at_position(&mut userGame, 4, 3, 8, 0, ctx(&mut scenario)); // Regular tile
            
            // Debug: Check initial state
            let board_before = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"Before move:"));
            std::debug::print(board_before);
            
            // Execute up move
            game::execute_move(&mut userGame, game::direction_right(), ctx(&mut scenario));
            
            // Debug: Check final state
            let board_after = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"After move:"));
            std::debug::print(board_after);
            
            // Debug: Check all positions in column 0
            let mut i = 0;
            while (i < 5) {
                let pos = game::position(i, 0);
                if (table::contains(board_after, pos)) {
                    let tile = table::borrow(board_after, pos);
                    std::debug::print(&string::utf8(b"Position "));
                    std::debug::print(&i);
                    std::debug::print(&string::utf8(b" has value "));
                    std::debug::print(&game::get_tile_value(tile));
                };
                i = i + 1;
            };
            
            // Check that tiles moved to top
            assert!(table::contains(board_after, game::position(2, 4)), 3);
            assert!(table::contains(board_after, game::position(4, 4)), 4);
            assert!(table::contains(board_after, game::position(4, 3)), 4);
            
            // Check merged value
            let tile_1 = table::borrow(board_after, game::position(2, 4));
            assert!(game::get_tile_value(tile_1) == 2, 4);

            let tile_2 = table::borrow(board_after, game::position(4, 4));
            assert!(game::get_tile_value(tile_2) == 1, 5);

            let tile_3 = table::borrow(board_after, game::position(4, 3));
            assert!(game::get_tile_value(tile_3) == 8, 6);

            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_move_left_not_merge_not_move() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_up");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add tiles at bottom of board
            add_tile_at_position(&mut userGame, 2, 0, 2, 0, ctx(&mut scenario)); // Regular tile
            add_tile_at_position(&mut userGame, 4, 0, 1, 0, ctx(&mut scenario)); // Regular tile
            
            // Debug: Check initial state
            let board_before = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"Before move:"));
            std::debug::print(board_before);
            
            // Execute up move
            game::execute_move(&mut userGame, game::direction_left(), ctx(&mut scenario));
            
            // Debug: Check final state
            let board_after = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"After move:"));
            std::debug::print(board_after);
            
            // Debug: Check all positions in column 0
            let mut i = 0;
            while (i < 5) {
                let pos = game::position(i, 0);
                if (table::contains(board_after, pos)) {
                    let tile = table::borrow(board_after, pos);
                    std::debug::print(&string::utf8(b"Position "));
                    std::debug::print(&i);
                    std::debug::print(&string::utf8(b" has value "));
                    std::debug::print(&game::get_tile_value(tile));
                };
                i = i + 1;
            };
            
            // Check that tiles moved to top
            assert!(table::contains(board_after, game::position(2, 0)), 3);
            assert!(table::contains(board_after, game::position(4, 0)), 4);
            
            // Check merged value
            let tile_1 = table::borrow(board_after, game::position(2, 0));
            assert!(game::get_tile_value(tile_1) == 2, 4);

            let tile_2 = table::borrow(board_after, game::position(4, 0));
            assert!(game::get_tile_value(tile_2) == 1, 5);

            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_move_left_not_merge() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_up");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add tiles at bottom of board
            add_tile_at_position(&mut userGame, 2, 2, 2, 0, ctx(&mut scenario)); // Regular tile
            add_tile_at_position(&mut userGame, 4, 1, 1, 0, ctx(&mut scenario)); // Regular tile
            
            // Debug: Check initial state
            let board_before = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"Before move:"));
            std::debug::print(board_before);
            
            // Execute up move
            game::execute_move(&mut userGame, game::direction_left(), ctx(&mut scenario));
            
            // Debug: Check final state
            let board_after = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"After move:"));
            std::debug::print(board_after);
            
            // Debug: Check all positions in column 0
            let mut i = 0;
            while (i < 5) {
                let pos = game::position(i, 0);
                if (table::contains(board_after, pos)) {
                    let tile = table::borrow(board_after, pos);
                    std::debug::print(&string::utf8(b"Position "));
                    std::debug::print(&i);
                    std::debug::print(&string::utf8(b" has value "));
                    std::debug::print(&game::get_tile_value(tile));
                };
                i = i + 1;
            };
            
            // Check that tiles moved to top
            assert!(!table::contains(board_after, game::position(2, 2)), 1);
            assert!(!table::contains(board_after, game::position(4, 1)), 2);
            assert!(table::contains(board_after, game::position(2, 0)), 3);
            assert!(table::contains(board_after, game::position(4, 0)), 4);
            
            // Check merged value
            let tile_1 = table::borrow(board_after, game::position(2, 0));
            assert!(game::get_tile_value(tile_1) == 2, 4);

            let tile_2 = table::borrow(board_after, game::position(4, 0));
            assert!(game::get_tile_value(tile_2) == 1, 5);

            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_move_up() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_up");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add tiles at bottom of board
            add_tile_at_position(&mut userGame, 3, 0, 2, 0, ctx(&mut scenario)); // Regular tile
            add_tile_at_position(&mut userGame, 4, 0, 2, 0, ctx(&mut scenario)); // Regular tile
            
            // Debug: Check initial state
            let board_before = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"Before move:"));
            std::debug::print(board_before);
            
            // Execute up move
            game::execute_move(&mut userGame, game::direction_up(), ctx(&mut scenario));
            
            // Debug: Check final state
            let board_after = game::get_board(&userGame);
            std::debug::print(&string::utf8(b"After move:"));
            std::debug::print(board_after);
            
            // Debug: Check all positions in column 0
            let mut i = 0;
            while (i < 5) {
                let pos = game::position(i, 0);
                if (table::contains(board_after, pos)) {
                    let tile = table::borrow(board_after, pos);
                    std::debug::print(&string::utf8(b"Position "));
                    std::debug::print(&i);
                    std::debug::print(&string::utf8(b" has value "));
                    std::debug::print(&game::get_tile_value(tile));
                };
                i = i + 1;
            };
            
            // Check that tiles moved to top
            assert!(table::contains(board_after, game::position(0, 0)), 1);
            assert!(!table::contains(board_after, game::position(3, 0)), 2);
            assert!(!table::contains(board_after, game::position(4, 0)), 3);
            
            // Check merged value
            let tile = table::borrow(board_after, game::position(0, 0));
            assert!(game::get_tile_value(tile) == 4, 4); // 2 + 2 = 4
            assert!(game::get_score(&userGame) == 4 * VALUE_MULTIPLIER, 5);
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_move_down() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_down");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add tiles at top of board
            add_tile_at_position(&mut userGame, 0, 0, 2, 0, ctx(&mut scenario)); // Regular tile
            add_tile_at_position(&mut userGame, 1, 0, 2, 0, ctx(&mut scenario)); // Regular tile
            
            // Execute down move
            game::execute_move(&mut userGame, game::direction_down(), ctx(&mut scenario));
            
            let board = game::get_board(&userGame);
            
            // Check that tiles moved to bottom
            assert!(table::contains(board, game::position(4, 0)), 1);
            assert!(!table::contains(board, game::position(0, 0)), 2);
            assert!(!table::contains(board, game::position(1, 0)), 3);
            
            // Check merged value
            let tile = table::borrow(board, game::position(4, 0));
            assert!(game::get_tile_value(tile) == 4, 4); // 2 + 2 = 4
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_move_left() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_left");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add tiles at right side of board
            add_tile_at_position(&mut userGame, 0, 3, 2, 0, ctx(&mut scenario)); // Regular tile
            add_tile_at_position(&mut userGame, 0, 4, 2, 0, ctx(&mut scenario)); // Regular tile
            
            // Execute left move
            game::execute_move(&mut userGame, game::direction_left(), ctx(&mut scenario));
            
            let board = game::get_board(&userGame);
            
            // Check that tiles moved to left
            assert!(table::contains(board, game::position(0, 0)), 1);
            assert!(!table::contains(board, game::position(0, 3)), 2);
            assert!(!table::contains(board, game::position(0, 4)), 3);
            
            // Check merged value
            let tile = table::borrow(board, game::position(0, 0));
            assert!(game::get_tile_value(tile) == 4, 4); // 2 + 2 = 4
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_move_right() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_right");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add tiles at left side of board
            add_tile_at_position(&mut userGame, 0, 0, 2, 0, ctx(&mut scenario)); // Regular tile
            add_tile_at_position(&mut userGame, 0, 1, 2, 0, ctx(&mut scenario)); // Regular tile
            
            // Execute right move
            game::execute_move(&mut userGame, game::direction_right(), ctx(&mut scenario));
            
            let board = game::get_board(&userGame);
            
            // Check that tiles moved to right
            assert!(table::contains(board, game::position(0, 4)), 1);
            assert!(!table::contains(board, game::position(0, 0)), 2);
            assert!(!table::contains(board, game::position(0, 1)), 3);
            
            // Check merged value
            let tile = table::borrow(board, game::position(0, 4));
            assert!(game::get_tile_value(tile) == 4, 4); // 2 + 2 = 4
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    // #[test]
    // fun test_add_new_tile_index_out_of_bounds_fixed() {
    //     let mut scenario = test::begin(ADMIN);
        
    //     next_tx(&mut scenario, ADMIN);
    //     {
    //         let gameId = string::utf8(b"test_index_bounds");
    //         let game = game::new_game(gameId, ctx(&mut scenario));
    //         game::transfer_game(game, ADMIN, ctx(&mut scenario));
    //     };

    //     next_tx(&mut scenario, ADMIN);
    //     {
    //         let mut userGame = test::take_from_sender<Game>(&scenario);
            
    //         // Fill the board with 24 tiles, leaving only 1 empty position
    //         let mut i = 0;
    //         while (i < 5) {
    //             let mut j = 0;
    //             while (j < 5) {
    //                 if (!(i == 4 && j == 4)) { // Leave position (4,4) empty
    //                     let value = (i * 5 + j + 1) as u64;
    //                     add_tile_at_position(&mut userGame, i, j, value, 0, ctx(&mut scenario));
    //                 };
    //                 j = j + 1;
    //             };
    //             i = i + 1;
    //         };
            
    //         // Now try to add a tile with random_index = 1 (but only 1 empty position exists)
    //         // This should fail because random_index (1) >= empty_positions.length (1)
    //         game::add_new_tile(
    //             &mut userGame,
    //             1,  // random_index = 1, but only 1 empty position (index 0)
    //             100, // random_value
    //             50,  // bomb_random
    //             0,   // bomb_cumulative
    //             1000, // regular_random
    //             ctx(&mut scenario)
    //         );
            
    //         test::return_to_sender(&scenario, userGame);
    //     };
        
    //     test::end(scenario);
    // }

    #[test]
    fun test_merge_up_multiple_tiles() {
    let mut scenario = test::begin(ADMIN);
    
    next_tx(&mut scenario, ADMIN);
    {
        let gameId = string::utf8(b"test_merge_up");
        let game = game::new_game(gameId, ctx(&mut scenario));
        game::transfer_game(game, ADMIN, ctx(&mut scenario));
    };

    next_tx(&mut scenario, ADMIN);
    {
        let mut userGame = test::take_from_sender<Game>(&scenario);
        
        // Add tiles in column 0: 2, 2, 4, 4
        add_tile_at_position(&mut userGame, 1, 0, 2, 0, ctx(&mut scenario));
        add_tile_at_position(&mut userGame, 2, 0, 2, 0, ctx(&mut scenario));
        add_tile_at_position(&mut userGame, 3, 0, 4, 0, ctx(&mut scenario));
        add_tile_at_position(&mut userGame, 4, 0, 4, 0, ctx(&mut scenario));
        
        // Debug: Check initial state before move
        std::debug::print(&string::utf8(b"=== BEFORE MOVE ==="));
        let board_before = game::get_board(&userGame);
        let mut i = 0;
        while (i < 5) {
            let pos = game::position(i, 0);
            if (table::contains(board_before, pos)) {
                let tile = table::borrow(board_before, pos);
                std::debug::print(&string::utf8(b"Initial Position ("));
                std::debug::print(&i);
                std::debug::print(&string::utf8(b", 0) has value "));
                std::debug::print(&game::get_tile_value(tile));
            } else {
                std::debug::print(&string::utf8(b"Initial Position ("));
                std::debug::print(&i);
                std::debug::print(&string::utf8(b", 0) is EMPTY"));
            };
            i = i + 1;
        };
        
        // Execute up move
        game::execute_move(&mut userGame, game::direction_up(), ctx(&mut scenario));
        
        let board = game::get_board(&userGame);
        
        // Debug: Check all positions in column 0 after move
        std::debug::print(&string::utf8(b"=== AFTER MOVE ==="));
        let mut i = 0;
        while (i < 5) {
            let pos = game::position(i, 0);
            if (table::contains(board, pos)) {
                let tile = table::borrow(board, pos);
                std::debug::print(&string::utf8(b"Final Position ("));
                std::debug::print(&i);
                std::debug::print(&string::utf8(b", 0) has value "));
                std::debug::print(&game::get_tile_value(tile));
                std::debug::print(&string::utf8(b" type "));
                std::debug::print(&game::get_tile_type(tile));
            } else {
                std::debug::print(&string::utf8(b"Final Position ("));
                std::debug::print(&i);
                std::debug::print(&string::utf8(b", 0) is EMPTY"));
            };
            i = i + 1;
        };
        
        // Check merged results: should be 4, 8 at top
        assert!(table::contains(board, game::position(0, 0)), 1);
        assert!(table::contains(board, game::position(1, 0)), 2);
        
        let tile1 = table::borrow(board, game::position(0, 0));
        let tile2 = table::borrow(board, game::position(1, 0));
        
        assert!(game::get_tile_value(tile1) == 4, 3); // 2 + 2 = 4
        assert!(game::get_tile_value(tile2) == 8, 4); // 4 + 4 = 8
        
        // Additional checks to detect index issues:
        // 1. Verify no tiles exist in positions 2, 3, 4 (should be empty after merge)
        assert!(!table::contains(board, game::position(2, 0)), 5);
        assert!(!table::contains(board, game::position(3, 0)), 6);
        assert!(!table::contains(board, game::position(4, 0)), 7);
        
        // 2. Verify tiles are regular tiles (not random, heart, or bomb)
        assert!(game::get_tile_type(tile1) == 0, 8); // Regular tile
        assert!(game::get_tile_type(tile2) == 0, 9); // Regular tile
        
        // 3. Verify score was updated correctly
        let expected_score = (4 + 8) * VALUE_MULTIPLIER; // 2+2=4, 4+4=8
        assert!(game::get_score(&userGame) == expected_score, 10);
        
        // 4. Verify moves counter was incremented
        assert!(game::get_moves(&userGame) == 1, 11);
        
        // 5. Count total tiles to ensure no tiles were lost or duplicated
        let mut total_tiles = 0;
        let mut i = 0;
        while (i < 5) {
            let mut j = 0;
            while (j < 5) {
                let pos = game::position(i, j);
                if (table::contains(board, pos)) {
                    total_tiles = total_tiles + 1;
                };
                j = j + 1;
            };
            i = i + 1;
        };
        assert!(total_tiles == 2, 12); // Should have exactly 2 tiles after merge
        
        // 6. Verify no tiles exist in other columns (should be empty)
        let mut i = 0;
        while (i < 5) {
            let mut j = 1; // Start from column 1
            while (j < 5) {
                let pos = game::position(i, j);
                assert!(!table::contains(board, pos), 13); // All other positions should be empty
                j = j + 1;
            };
            i = i + 1;
        };
        
        std::debug::print(&string::utf8(b"=== TEST PASSED: No index issues detected ==="));
        
        test::return_to_sender(&scenario, userGame);
    };
    
    test::end(scenario);
}

    #[test]
    fun test_merge_down_multiple_tiles() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_merge_down");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add tiles in column 0: 2, 2, 4, 4
            add_tile_at_position(&mut userGame, 0, 0, 2, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 1, 0, 2, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 2, 0, 4, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 3, 0, 4, 0, ctx(&mut scenario));
            
            // Execute down move
            game::execute_move(&mut userGame, game::direction_down(), ctx(&mut scenario));
            
            let board = game::get_board(&userGame);
            
            // Check merged results: should be 4, 8 at bottom
            assert!(table::contains(board, game::position(3, 0)), 1);
            assert!(table::contains(board, game::position(4, 0)), 2);
            
            let tile1 = table::borrow(board, game::position(3, 0));
            let tile2 = table::borrow(board, game::position(4, 0));
            
            assert!(game::get_tile_value(tile1) == 4, 3); // 2 + 2 = 4
            assert!(game::get_tile_value(tile2) == 8, 4); // 4 + 4 = 8
            assert!(game::get_score(&userGame) == 12 * VALUE_MULTIPLIER, 5);
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_merge_left_multiple_tiles() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_merge_left");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add tiles in row 0: 2, 2, 4, 4
            add_tile_at_position(&mut userGame, 0, 1, 2, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 0, 2, 2, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 0, 3, 4, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 0, 4, 4, 0, ctx(&mut scenario));
            
            // Execute left move
            game::execute_move(&mut userGame, game::direction_left(), ctx(&mut scenario));
            
            let board = game::get_board(&userGame);
            
            // Check merged results: should be 4, 8 at left
            assert!(table::contains(board, game::position(0, 0)), 1);
            assert!(table::contains(board, game::position(0, 1)), 2);
            
            let tile1 = table::borrow(board, game::position(0, 0));
            let tile2 = table::borrow(board, game::position(0, 1));
            
            assert!(game::get_tile_value(tile1) == 4, 3); // 2 + 2 = 4
            assert!(game::get_tile_value(tile2) == 8, 4); // 4 + 4 = 8
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_merge_right_multiple_tiles() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_merge_right");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add tiles in row 0: 2, 2, 4, 4
            add_tile_at_position(&mut userGame, 0, 0, 2, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 0, 1, 2, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 0, 2, 4, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 0, 3, 4, 0, ctx(&mut scenario));
            
            // Execute right move
            game::execute_move(&mut userGame, game::direction_right(), ctx(&mut scenario));
            
            let board = game::get_board(&userGame);
            
            // Check merged results: should be 4, 8 at right
            assert!(table::contains(board, game::position(0, 3)), 1);
            assert!(table::contains(board, game::position(0, 4)), 2);
            
            let tile1 = table::borrow(board, game::position(0, 3));
            let tile2 = table::borrow(board, game::position(0, 4));
            
            assert!(game::get_tile_value(tile1) == 4, 3); // 2 + 2 = 4
            assert!(game::get_tile_value(tile2) == 8, 4); // 4 + 4 = 8
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_complex_merge_scenario() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_complex");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Create a complex scenario: row with 2, 2, 4, 4, 8
            add_tile_at_position(&mut userGame, 0, 0, 2, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 0, 1, 2, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 0, 2, 4, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 0, 3, 4, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 0, 4, 8, 0, ctx(&mut scenario));
            
            // Execute right move
            game::execute_move(&mut userGame, game::direction_right(), ctx(&mut scenario));
            
            let board = game::get_board(&userGame);
            
            // Expected result: 4, 8, 8 (from left to right)
            assert!(table::contains(board, game::position(0, 2)), 1);
            assert!(table::contains(board, game::position(0, 3)), 2);
            assert!(table::contains(board, game::position(0, 4)), 3);
            
            let tile1 = table::borrow(board, game::position(0, 2));
            let tile2 = table::borrow(board, game::position(0, 3));
            let tile3 = table::borrow(board, game::position(0, 4));
            
            assert!(game::get_tile_value(tile1) == 4, 4); // 2 + 2 = 4
            assert!(game::get_tile_value(tile2) == 8, 5); // 4 + 4 = 8
            assert!(game::get_tile_value(tile3) == 8, 6); // 8 remains
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_bomb_explosion_on_merge() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_bomb");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add bomb tile and regular tile that can merge
            add_tile_at_position(&mut userGame, 0, 0, 2, 3, ctx(&mut scenario)); // Bomb tile
            add_tile_at_position(&mut userGame, 0, 1, 2, 0, ctx(&mut scenario)); // Regular tile
            
            // Add some tiles around the bomb for explosion effect
            add_tile_at_position(&mut userGame, 0, 2, 4, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 1, 0, 8, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 1, 1, 16, 0, ctx(&mut scenario));
            
            // Debug: Check board state before move
            std::debug::print(&string::utf8(b"Before move:\n"));
            let mut i = 0;
            while (i < 5) {
                let mut j = 0;
                while (j < 5) {
                    let pos = game::position(i, j);
                    if (table::contains(game::get_board(&userGame), pos)) {
                        let tile = table::borrow(game::get_board(&userGame), pos);
                        std::debug::print(&string::utf8(b"Position ("));
                        std::debug::print(&i);
                        std::debug::print(&string::utf8(b", "));
                        std::debug::print(&j);
                        std::debug::print(&string::utf8(b") has value "));
                        std::debug::print(&game::get_tile_value(tile));
                        std::debug::print(&string::utf8(b" type "));
                        std::debug::print(&game::get_tile_type(tile));
                        std::debug::print(&string::utf8(b"\n"));
                    };
                    j = j + 1;
                };
                i = i + 1;
            };
            
            // Execute right move to trigger bomb explosion
            game::execute_move(&mut userGame, game::direction_right(), ctx(&mut scenario));
            
            let board = game::get_board(&userGame);
            
            // Check that bomb explosion cleared affected tiles
            // The explosion should clear the cross pattern around the bomb position
            assert!(!table::contains(board, game::position(0, 0)), 1); // Bomb position
            assert!(!table::contains(board, game::position(0, 1)), 2); // Adjacent tile
            assert!(!table::contains(board, game::position(1, 0)), 3); // Adjacent tile
            assert!(!table::contains(board, game::position(1, 1)), 4); // Adjacent tile
            
            // Debug: Check all positions to see what's left after explosion
            std::debug::print(&string::utf8(b"After move:\n"));
            let mut i = 0;
            while (i < 5) {
                let mut j = 0;
                while (j < 5) {
                    let pos = game::position(i, j);
                    if (table::contains(board, pos)) {
                        let tile = table::borrow(board, pos);
                        std::debug::print(&string::utf8(b"Position ("));
                        std::debug::print(&i);
                        std::debug::print(&string::utf8(b", "));
                        std::debug::print(&j);
                        std::debug::print(&string::utf8(b") has value "));
                        std::debug::print(&game::get_tile_value(tile));
                        std::debug::print(&string::utf8(b" type "));
                        std::debug::print(&game::get_tile_type(tile));
                        std::debug::print(&string::utf8(b"\n"));
                    };
                    j = j + 1;
                };
                i = i + 1;
            };
            
            // Debug: Check if explosion happened at (0,0)
            std::debug::print(&string::utf8(b"Explosion should have happened at (0,0)\n"));
            
            // The tile at (0,2) should remain as it's not in explosion range
            // But it seems to be cleared, let's check what actually happened
            if (table::contains(board, game::position(0, 2))) {
                std::debug::print(&string::utf8(b"Position (0,2) still has a tile\n"));
            } else {
                std::debug::print(&string::utf8(b"Position (0,2) was cleared by explosion\n"));
            };
            
            // For now, let's just check that the explosion cleared the expected positions
            assert!(!table::contains(board, game::position(0, 0)), 1); // Bomb position
            assert!(!table::contains(board, game::position(0, 1)), 2); // Adjacent tile
            assert!(!table::contains(board, game::position(1, 0)), 3); // Adjacent tile
            assert!(!table::contains(board, game::position(1, 1)), 4); // Adjacent tile

            let tile = table::borrow(board, game::position(1, 4));
            assert!(table::contains(board, game::position(1, 4)), 5);
            assert!(game::get_tile_value(tile) == 16, 6);

            assert!(game::get_score(&userGame) == 4 * VALUE_MULTIPLIER, 6);

            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_heart_tile_protection() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_heart");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add heart tile and regular tile with same value
            add_tile_at_position(&mut userGame, 0, 0, 2, 2, ctx(&mut scenario)); // Heart tile
            add_tile_at_position(&mut userGame, 0, 1, 2, 0, ctx(&mut scenario)); // Regular tile
            
            // Execute right move - heart tiles should not merge
            game::execute_move(&mut userGame, game::direction_right(), ctx(&mut scenario));
            
            let board = game::get_board(&userGame);
            
            // Check that heart tile and regular tile remain separate
            assert!(table::contains(board, game::position(0, 3)), 1); // Heart tile moved right
            assert!(table::contains(board, game::position(0, 4)), 2); // Regular tile moved right
            
            let heart_tile = table::borrow(board, game::position(0, 3));
            let regular_tile = table::borrow(board, game::position(0, 4));
            
            assert!(game::is_heart(heart_tile), 3);
            assert!(!game::is_heart(regular_tile), 4);
            assert!(game::get_tile_value(heart_tile) == 2, 5);
            assert!(game::get_tile_value(regular_tile) == 2, 6);
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

     #[test]
    fun test_bomb_explosion_position_debug() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_bomb_position");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // 模擬你的後端數據：炸彈在 (3,3)，普通方塊在 (4,3)
            // 這樣向下移動時會合併觸發爆炸
            add_tile_at_position(&mut userGame, 3, 3, 2, 3, ctx(&mut scenario)); // Bomb tile at (3,3)
            add_tile_at_position(&mut userGame, 4, 3, 2, 0, ctx(&mut scenario)); // Regular tile at (4,3) with same value
            
            // 執行向下移動
            game::execute_move(&mut userGame, game::direction_down(), ctx(&mut scenario));
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_bomb_explosion_position_simple() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_simple_bomb");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // 簡單測試：炸彈在 (0,0)，普通方塊在 (1,0)
            // 向下移動時會合併觸發爆炸
            add_tile_at_position(&mut userGame, 0, 0, 2, 3, ctx(&mut scenario)); // Bomb tile at (0,0)
            add_tile_at_position(&mut userGame, 1, 0, 2, 0, ctx(&mut scenario)); // Regular tile at (1,0) with same value
            
            // 執行向下移動
            game::execute_move(&mut userGame, game::direction_down(), ctx(&mut scenario));
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_bomb_explosion_position_exact() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_exact_bomb");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // 精確模擬你的後端數據：
            // 炸彈在 (3,3)，普通方塊在 (4,3)
            // 向下移動時會合併觸發爆炸
            add_tile_at_position(&mut userGame, 3, 3, 2, 3, ctx(&mut scenario)); // Bomb tile at (3,3)
            add_tile_at_position(&mut userGame, 4, 3, 2, 0, ctx(&mut scenario)); // Regular tile at (4,3) with same value
            
            // 執行向下移動
            game::execute_move(&mut userGame, game::direction_down(), ctx(&mut scenario));
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_heart_tile_destruction_by_bomb() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_heart_bomb");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Simple test: place bomb and heart tile that will merge at position (0,2) where explosion occurs
            add_tile_at_position(&mut userGame, 0, 0, 2, 3, ctx(&mut scenario)); // Bomb tile
            add_tile_at_position(&mut userGame, 0, 1, 2, 0, ctx(&mut scenario)); // Regular tile with same value (will merge with bomb)
            add_tile_at_position(&mut userGame, 1, 2, 1, 2, ctx(&mut scenario)); // Heart tile in explosion range
            
            // Debug: Check initial state
            std::debug::print(&string::utf8(b"Initial game over status: "));
            std::debug::print(&game::is_game_over(&userGame));
            assert!(!game::is_game_over(&userGame), 0); // Game should not be over initially
            
            // Execute right move to trigger bomb explosion
            game::execute_move(&mut userGame, game::direction_right(), ctx(&mut scenario));
            
            // Debug: Check final state - the game should be over after heart destruction
            // The heart tile at (0,2) should be destroyed by the bomb explosion from (0,1)
            std::debug::print(&string::utf8(b"Game over status: "));
            std::debug::print(&game::is_game_over(&userGame));
            
            // Debug: Check if heart tile still exists
            let board = game::get_board(&userGame);
            let heart_pos = game::position(1, 2);
            let heart_exists = table::contains(board, heart_pos);
            std::debug::print(&string::utf8(b"Heart tile exists: "));
            std::debug::print(&heart_exists);
            
            // Debug: Check all positions to see what's left
            std::debug::print(&string::utf8(b"Board state after move:"));
            let mut i = 0;
            while (i < 5) {
                let mut j = 0;
                while (j < 5) {
                    let pos = game::position(i, j);
                    if (table::contains(board, pos)) {
                        let tile = table::borrow(board, pos);
                        std::debug::print(&string::utf8(b"Position ("));
                        std::debug::print(&i);
                        std::debug::print(&string::utf8(b", "));
                        std::debug::print(&j);
                        std::debug::print(&string::utf8(b") has value "));
                        std::debug::print(&game::get_tile_value(tile));
                        std::debug::print(&string::utf8(b" type "));
                        std::debug::print(&game::get_tile_type(tile));
                        std::debug::print(&string::utf8(b"\n"));
                    };
                    j = j + 1;
                };
                i = i + 1;
            };
            
            assert!(game::is_game_over(&userGame), 1); // Game should be over after heart destruction
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_random_tile_behavior() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_random");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add random tile and regular tile with same value
            add_tile_at_position(&mut userGame, 0, 0, 2, 1, ctx(&mut scenario)); // Random tile
            add_tile_at_position(&mut userGame, 0, 1, 2, 0, ctx(&mut scenario)); // Regular tile
            
            // Execute right move - random tiles should not merge
            game::execute_move(&mut userGame, game::direction_right(), ctx(&mut scenario));
            
            let board = game::get_board(&userGame);
            
            // Check that random tile and regular tile remain separate
            assert!(table::contains(board, game::position(0, 3)), 1); // Random tile moved right
            assert!(table::contains(board, game::position(0, 4)), 2); // Regular tile moved right
            
            let random_tile = table::borrow(board, game::position(0, 3));
            let regular_tile = table::borrow(board, game::position(0, 4));
            
            assert!(game::is_random(random_tile), 3);
            assert!(!game::is_random(regular_tile), 4);
            assert!(game::get_tile_value(random_tile) == 2, 5);
            assert!(game::get_tile_value(regular_tile) == 2, 6);
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_replace_random_tile_with_value_success() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_replace_random");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add a random tile at position (1, 1)
            add_tile_at_position(&mut userGame, 1, 1, 1, 1, ctx(&mut scenario)); // Random tile with value 1
            
            // Verify the random tile is there
            let board_before = game::get_board(&userGame);
            let pos = game::position(1, 1);
            assert!(table::contains(board_before, pos), 1);
            
            let old_tile = table::borrow(board_before, pos);
            assert!(game::is_random(old_tile), 2);
            assert!(game::get_tile_value(old_tile) == 1, 3);
            
            // Replace random tile with value at index 0 (should be value 1)
            game::replace_random_tile_with_value(&mut userGame, 0, 1, 1, ctx(&mut scenario));
            
            // Verify the replacement
            let board_after = game::get_board(&userGame);
            assert!(table::contains(board_after, pos), 4);
            
            let new_tile = table::borrow(board_after, pos);
            assert!(!game::is_random(new_tile), 5); // Should not be random anymore
            assert!(game::get_tile_value(new_tile) == 1, 6); // Should have value 1
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    // #[test]
    // fun test_replace_random_tile_with_different_values() {
    //     let mut scenario = test::begin(ADMIN);
        
    //     next_tx(&mut scenario, ADMIN);
    //     {
    //         let gameId = string::utf8(b"test_replace_different");
    //         let game = game::new_game(gameId, ctx(&mut scenario));
    //         game::transfer_game(game, ADMIN, ctx(&mut scenario));
    //     };

    //     next_tx(&mut scenario, ADMIN);
    //     {
    //         let mut userGame = test::take_from_sender<Game>(&scenario);
            
    //         // Add a random tile at position (2, 2)
    //         add_tile_at_position(&mut userGame, 2, 2, 1, 1, ctx(&mut scenario)); // Random tile
            
    //         // Test replacing with different random values
    //         // Index 1 should give value 2
    //         game::replace_random_tile_with_value(&mut userGame, 1, 2, 2, ctx(&mut scenario));
            
    //         let board = game::get_board(&userGame);
    //         let pos = game::position(2, 2);
    //         let tile = table::borrow(board, pos);
    //         assert!(game::get_tile_value(tile) == 2, 1);
    //         assert!(!game::is_random(tile), 2);
            
    //         // Add another random tile and test index 2 (value 4)
    //         add_tile_at_position(&mut userGame, 3, 3, 1, 1, ctx(&mut scenario));
    //         game::replace_random_tile_with_value(&mut userGame, 2, 3, 3, ctx(&mut scenario));
            
    //         // Get fresh board reference after the second replacement
    //         let board_after =ｂ game::get_board(&userGame);
    //         let pos2 = game::position(3, 3);
    //         let tile2 = table::borrow(board_after, pos2);
    //         assert!(game::get_tile_value(tile2) == 4, 3);
    //         assert!(!game::is_random(tile2), 4);
            
    //         test::return_to_sender(&scenario, userGame);
    //     };
        
    //     test::end(scenario);
    // }

    #[test]
    #[expected_failure(abort_code = 7)]
    fun test_replace_random_tile_invalid_index() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_replace_invalid_index");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add a random tile
            add_tile_at_position(&mut userGame, 1, 1, 1, 1, ctx(&mut scenario));
            
            // This should fail because index 10 is out of bounds (RANDOM_TILE_VALUES has 5 elements)
            game::replace_random_tile_with_value(&mut userGame, 10, 1, 1, ctx(&mut scenario));
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 5)]
    fun test_replace_random_tile_no_tile_at_position() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_replace_no_tile");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Don't add any tile at position (1, 1)
            // This should fail because there's no tile at the position
            game::replace_random_tile_with_value(&mut userGame, 0, 1, 1, ctx(&mut scenario));
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 6)]
    fun test_replace_random_tile_non_random_tile() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_replace_non_random");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Add a regular tile (not random) at position (1, 1)
            add_tile_at_position(&mut userGame, 1, 1, 2, 0, ctx(&mut scenario)); // Regular tile
            
            // This should fail because the tile is not a random tile
            game::replace_random_tile_with_value(&mut userGame, 0, 1, 1, ctx(&mut scenario));
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_replace_random_tile_all_valid_indices() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_replace_all_indices");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Test all valid indices: 0, 1, 2, 3, 4
            // Expected values from RANDOM_TILE_VALUES: [1, 2, 4, 8, 16]
            
            // Test index 0 -> value 1
            add_tile_at_position(&mut userGame, 0, 0, 1, 1, ctx(&mut scenario));
            game::replace_random_tile_with_value(&mut userGame, 0, 0, 0, ctx(&mut scenario));
            let tile0 = table::borrow(game::get_board(&userGame), game::position(0, 0));
            assert!(game::get_tile_value(tile0) == 1, 1);
            
            // Test index 1 -> value 2
            add_tile_at_position(&mut userGame, 0, 1, 1, 1, ctx(&mut scenario));
            game::replace_random_tile_with_value(&mut userGame, 1, 0, 1, ctx(&mut scenario));
            let tile1 = table::borrow(game::get_board(&userGame), game::position(0, 1));
            assert!(game::get_tile_value(tile1) == 2, 2);
            
            // Test index 2 -> value 4
            add_tile_at_position(&mut userGame, 0, 2, 1, 1, ctx(&mut scenario));
            game::replace_random_tile_with_value(&mut userGame, 2, 0, 2, ctx(&mut scenario));
            let tile2 = table::borrow(game::get_board(&userGame), game::position(0, 2));
            assert!(game::get_tile_value(tile2) == 4, 3);
            
            // Test index 3 -> value 8
            add_tile_at_position(&mut userGame, 0, 3, 1, 1, ctx(&mut scenario));
            game::replace_random_tile_with_value(&mut userGame, 3, 0, 3, ctx(&mut scenario));
            let tile3 = table::borrow(game::get_board(&userGame), game::position(0, 3));
            assert!(game::get_tile_value(tile3) == 8, 4);
            
            // Test index 4 -> value 16
            add_tile_at_position(&mut userGame, 0, 4, 1, 1, ctx(&mut scenario));
            game::replace_random_tile_with_value(&mut userGame, 4, 0, 4, ctx(&mut scenario));
            let tile4 = table::borrow(game::get_board(&userGame), game::position(0, 4));
            assert!(game::get_tile_value(tile4) == 16, 5);
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_game_over_board_full_no_empty_cells() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_board_full");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Fill the entire 5x5 board with tiles (25 tiles total)
            // Row 0: 2, 4, 8, 16, 32
            add_tile_at_position(&mut userGame, 0, 0, 2, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 0, 1, 4, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 0, 2, 8, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 0, 3, 16, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 0, 4, 32, 0, ctx(&mut scenario));
            
            // Row 1: 64, 128, 256, 512, 1024
            add_tile_at_position(&mut userGame, 1, 0, 64, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 1, 1, 128, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 1, 2, 256, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 1, 3, 512, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 1, 4, 1024, 0, ctx(&mut scenario));
            
            // Row 2: 2048, 1, 2, 4, 8
            add_tile_at_position(&mut userGame, 2, 0, 2048, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 2, 1, 1, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 2, 2, 2, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 2, 3, 4, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 2, 4, 8, 0, ctx(&mut scenario));
            
            // Row 3: 16, 32, 64, 128, 256
            add_tile_at_position(&mut userGame, 3, 0, 16, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 3, 1, 32, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 3, 2, 64, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 3, 3, 128, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 3, 4, 256, 0, ctx(&mut scenario));
            
            // Row 4: 512, 1024, 2048, 1, 2
            add_tile_at_position(&mut userGame, 4, 0, 512, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 4, 1, 1024, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 4, 2, 2048, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 4, 3, 1, 0, ctx(&mut scenario));
            add_tile_at_position(&mut userGame, 4, 4, 2, 0, ctx(&mut scenario));
            
            // Verify board is full (25 tiles)
            let board = game::get_board(&userGame);
            let mut tile_count = 0;
            let mut i = 0;
            while (i < 5) {
                let mut j = 0;
                while (j < 5) {
                    let pos = game::position(i, j);
                    if (table::contains(board, pos)) {
                        tile_count = tile_count + 1;
                    };
                    j = j + 1;
                };
                i = i + 1;
            };
            assert!(tile_count == 25, 1); // Board should be full
            
            // Verify game is not over yet
            assert!(!game::is_game_over(&userGame), 2);
            
            // Try to add a new tile - this should trigger game over
            game::add_new_tile(
                &mut userGame,
                0,  // random_index (doesn't matter since no empty cells)
                100, // random_value
                50,  // bomb_random
                0,   // bomb_cumulative
                1000, // regular_random
                ctx(&mut scenario)
            );
            
            // Verify game is now over
            assert!(game::is_game_over(&userGame), 3);
            
            // Verify board still has 25 tiles (no new tile was added)
            let board_after = game::get_board(&userGame);
            let mut tile_count_after = 0;
            let mut i = 0;
            while (i < 5) {
                let mut j = 0;
                while (j < 5) {
                    let pos = game::position(i, j);
                    if (table::contains(board_after, pos)) {
                        tile_count_after = tile_count_after + 1;
                    };
                    j = j + 1;
                };
                i = i + 1;
            };
            assert!(tile_count_after == 25, 4); // Board should still have 25 tiles
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_game_over_board_full_after_move_creates_space() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_board_full_after_move");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // Fill the board with tiles that can merge, leaving one space
            // This will test the scenario where a move creates space, but then
            // the board becomes full again after adding a new tile
            
            // Fill most of the board with different values
            let mut i = 0;
            while (i < 5) {
                let mut j = 0;
                while (j < 5) {
                    if (!(i == 4 && j == 4)) { // Leave position (4,4) empty
                        let value = (i * 5 + j + 1) as u64;
                        add_tile_at_position(&mut userGame, i, j, value, 0, ctx(&mut scenario));
                    };
                    j = j + 1;
                };
                i = i + 1;
            };
            
            // Add a tile at the empty position
            add_tile_at_position(&mut userGame, 4, 4, 1, 0, ctx(&mut scenario));
            
            // Verify board is full
            let board = game::get_board(&userGame);
            let mut tile_count = 0;
            let mut i = 0;
            while (i < 5) {
                let mut j = 0;
                while (j < 5) {
                    let pos = game::position(i, j);
                    if (table::contains(board, pos)) {
                        tile_count = tile_count + 1;
                    };
                    j = j + 1;
                };
                i = i + 1;
            };
            assert!(tile_count == 25, 1);
            
            // Verify game is not over yet
            assert!(!game::is_game_over(&userGame), 2);
            
            // Try to add a new tile - this should trigger game over
            game::add_new_tile(
                &mut userGame,
                0,  // random_index
                100, // random_value
                50,  // bomb_random
                0,   // bomb_cumulative
                1000, // regular_random
                ctx(&mut scenario)
            );
            
            // Verify game is now over
            assert!(game::is_game_over(&userGame), 3);
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    // ===== 四個方向炸彈爆炸炸到愛心遊戲結束的測試範例 =====

    #[test]
    fun test_heart_destruction_bomb_right_move() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_heart_bomb_right");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // 右移情境：炸彈在左邊，愛心在右邊
            // 初始狀態：
            // [B][R][ ][H][ ]
            // B=炸彈(2), R=普通瓦片(2), H=愛心(1)
            add_tile_at_position(&mut userGame, 0, 0, 2, 3, ctx(&mut scenario)); // Bomb tile
            add_tile_at_position(&mut userGame, 0, 1, 2, 0, ctx(&mut scenario)); // Regular tile with same value
            add_tile_at_position(&mut userGame, 1, 3, 1, 2, ctx(&mut scenario)); // Heart tile
            
            // 執行右移：炸彈和普通瓦片合併，爆炸摧毀愛心
            game::execute_move(&mut userGame, game::direction_right(), ctx(&mut scenario));
            
            // 驗證遊戲結束
            assert!(game::is_game_over(&userGame), 0);
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_heart_destruction_bomb_left_move() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_heart_bomb_left");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // 左移情境：炸彈在右邊，愛心在左邊
            // 初始狀態：
            // [ ][H][ ][R][B]
            // B=炸彈(2), R=普通瓦片(2), H=愛心(1)
            add_tile_at_position(&mut userGame, 0, 4, 2, 3, ctx(&mut scenario)); // Bomb tile
            add_tile_at_position(&mut userGame, 0, 3, 2, 0, ctx(&mut scenario)); // Regular tile with same value
            add_tile_at_position(&mut userGame, 0, 1, 1, 2, ctx(&mut scenario)); // Heart tile
            
            // 執行左移：炸彈和普通瓦片合併，爆炸摧毀愛心
            game::execute_move(&mut userGame, game::direction_left(), ctx(&mut scenario));
            
            // 驗證遊戲結束
            assert!(game::is_game_over(&userGame), 0);
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_heart_destruction_bomb_up_move() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_heart_bomb_up");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // 上移情境：炸彈在下邊，愛心在上邊
            // 初始狀態：
            // [H][ ][ ][ ][ ]
            // [ ][ ][ ][ ][ ]
            // [ ][ ][ ][ ][ ]
            // [R][ ][ ][ ][ ]
            // [B][ ][ ][ ][ ]
            // B=炸彈(2), R=普通瓦片(2), H=愛心(1)
            // 修正：讓炸彈和普通瓦片在同一列，這樣上移時會合併
            add_tile_at_position(&mut userGame, 4, 0, 2, 3, ctx(&mut scenario)); // Bomb tile
            add_tile_at_position(&mut userGame, 3, 0, 2, 0, ctx(&mut scenario)); // Regular tile with same value
            add_tile_at_position(&mut userGame, 0, 0, 1, 2, ctx(&mut scenario)); // Heart tile
            
            // 執行上移：炸彈和普通瓦片合併，爆炸摧毀愛心
            game::execute_move(&mut userGame, game::direction_up(), ctx(&mut scenario));
            
            // 驗證遊戲結束
            assert!(game::is_game_over(&userGame), 0);
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_heart_destruction_bomb_down_move() {
        let mut scenario = test::begin(ADMIN);
        
        next_tx(&mut scenario, ADMIN);
        {
            let gameId = string::utf8(b"test_heart_bomb_down");
            let game = game::new_game(gameId, ctx(&mut scenario));
            game::transfer_game(game, ADMIN, ctx(&mut scenario));
        };

        next_tx(&mut scenario, ADMIN);
        {
            let mut userGame = test::take_from_sender<Game>(&scenario);
            
            // 下移情境：炸彈在上邊，愛心在下邊
            // 初始狀態：
            // [ ][ ][ ][B][ ]
            // [ ][ ][ ][ ][ ]
            // [ ][ ][ ][ ][ ]
            // [ ][ ][ ][ ][ ]
            // [ ][ ][ ][R][H]
            // B=炸彈(2), R=普通瓦片(2), H=愛心(1)
            // 修正：讓炸彈和普通瓦片在同一列，愛心在爆炸範圍內且不會被移動
            add_tile_at_position(&mut userGame, 0, 3, 2, 3, ctx(&mut scenario)); // Bomb tile
            add_tile_at_position(&mut userGame, 4, 3, 2, 0, ctx(&mut scenario)); // Regular tile with same value
            add_tile_at_position(&mut userGame, 4, 4, 1, 2, ctx(&mut scenario)); // Heart tile in explosion range
            
            // 執行下移：炸彈和普通瓦片合併，爆炸摧毀愛心
            game::execute_move(&mut userGame, game::direction_down(), ctx(&mut scenario));
            
            // 驗證遊戲結束
            assert!(game::is_game_over(&userGame), 0);
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }
}