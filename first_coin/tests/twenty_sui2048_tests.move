#[test_only]
module TWENTY_PACKAGE::game_tests {
    use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};
    use std::string::{Self, String};
    use sui::table::{Self, Table};
    use TWENTY_PACKAGE::game::{Self, Game};

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
                1,  // 位置亂數 0: (0,0), 1: (0,1), 2: (0,2), 3: (0,3), 4: (1,0), 5: (1,1), 6: (1,2), 7: (1,3),
                    // 8: (2,0), 9: (2,1), 10: (2,2), 11: (2,3), 12: (3,0), 13: (3,1), 14: (3,2), 15: (3,3)
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

    #[test]
    fun test_right_move() {
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
                1,  // 位置亂數 0: (0,0), 1: (0,1), 2: (0,2), 3: (0,3), 4: (1,0), 5: (1,1), 6: (1,2), 7: (1,3),
                    // 8: (2,0), 9: (2,1), 10: (2,2), 11: (2,3), 12: (3,0), 13: (3,1), 14: (3,2), 15: (3,3)
                4, // random rate
                1, // bomb rate
                1, // bomb rate calculation
                500, 
                ctx(&mut scenario));

            game::add_new_tile(
                &mut userGame,
                1, 
                4,
                1,
                1,
                500, 
                ctx(&mut scenario));
            
            let board = game::get_board(&userGame);
            // let state = game::get_state(&userGame);
            let expected_position = game::position(0, 1);

            // 添加後確認位置被佔用
            // assert!(table::contains(board, expected_position), 1);
            
            // 獲取並檢查 tile
            let tile = table::borrow(board, expected_position);

            let expected_value = 1;
            let value = game::get_tile_value(tile);
            // assert!(value == expected_value, 1);

            game::execute_move(&mut userGame, game::direction_right(), ctx(&mut scenario));
            
            test::return_to_sender(&scenario, userGame);
        };
        
        test::end(scenario);
    }
}
