package UI;

use strict;
use warnings;

use Nice::Try;
use Data::Dumper;
use List::Util qw(min max);
use List::Util qw(all);
use Game;
use Model::Board;

use 5.010;

my $menu = "
    =====DOMINO=====
    [1] Add player to game
    [2] View added players
    [3] Start Game

    [x] Exit
";

sub run {
  NEW_GAME:
    my $board = Model::Board->new;
    my $players;

  PRINT_MENU:
    say $menu;
    say "-------------------------------------";
    say "Your option: ";
    chomp( my $cmd = <STDIN> );

    if ( $cmd eq '1' ) {
        say "-------------------------------------";
        say "Enter your name: ";
        say "-------------------------------------";
        chomp( my $name = <STDIN> );

        try {
            $board->add_player( Model::Player->new( name => $name ) );
            $board->validate_players;
            say "-------------------------------------";
            say "Player '$name' added.";
            say "-------------------------------------";
            goto PRINT_MENU;
        }
        catch ( ValidationException $e) {
            say "-------------------------------------";
            say "Error adding player! [$e]";
            say "-------------------------------------";
            goto PRINT_MENU;
        }
        catch ( NonUniqueObjectException $e) {
            say "-------------------------------------";
            say "Player '$name'  cannot be added. [$e]";
            say "-------------------------------------";
            goto PRINT_MENU;
        }
        catch ( BigObjectNumberException $e) {
            say "-------------------------------------";
            say "Player '$name' cannot be added. [$e]";
            say "-------------------------------------";
            goto PRINT_MENU;
        }
    }
    elsif ( $cmd eq '2' ) {
        say "-------------------------------------";
        say "Players: \n" . $board->stringify_players;
        say "-------------------------------------";
        goto PRINT_MENU;
    }
    elsif ( $cmd eq '3' ) {
        try {
            $board->validate_minimum_players;
            say "-------------------------------------";
            say "Starting game...";
            my $winner = play($board);
            say "-------------------------------------";
            say "Congratulations $winner!";
            say "-------------------------------------";
          START_GAME_OPTION:
            say "Start a new game? (y|n)";
            chomp( my $start_game_option = <STDIN> );

            if ( $start_game_option eq 'y' ) {
                goto NEW_GAME;
            }
            elsif ( $start_game_option eq 'n' ) {
                say "Thank you for playing!";
                exit(0);
            }
            else {
                say "Invalid option!";
                goto START_GAME_OPTION;
            }
        }
        catch ( SmallObjectNumberException $e) {
            say "Cannot start game. [$e]";
        }
    }
    elsif ( $cmd eq 'x' ) {
        say "Thank you for playing!";
        exit(0);
    }
    else {
        say "Invalid option!";
        goto PRINT_MENU;
    }
}

sub play {
    my ($board) = @_;

    # Shuffle the deck of pieces
    Game::fisher_yates_shuffle( $board->available_pieces );
    say "-------------------------------------";
    say "Everybody should pick their initial 7 pieces:";
    foreach my $current_player ( @{ $board->players } ) {
        say "-------------------------------------";
        say $current_player->name . "'s turn:";

        while ( scalar @{ $current_player->pieces } < 7 ) {
            pick_piece( $board, $current_player );
        }
        say $current_player->name
          . "'s pieces:"
          . $current_player->stringify_pieces;
    }
    say "-------------------------------------";
    say "Let's decide what will be the players order:";
    my $picked_pieces;

    foreach my $current_player ( @{ $board->players } ) {
        say "-------------------------------------";
        say $current_player->name . "'s turn:";
        say $current_player->name
          . "'s pieces:"
          . $current_player->stringify_pieces;

      PICK_INITIAL_PIECE:
        say "-------------------------------------";
        say "Pick a piece.";
        say "-------------------------------------";
        say "Your option:";
        chomp( my $picked_piece_number = <STDIN> );

        my $last_piece_index = $current_player->pieces_count - 1;
        my $pattern          = join '|', 0 .. $last_piece_index;

        if ( $picked_piece_number !~ m/^(?:$pattern)$/ ) {
            say "-------------------------------------";
            say "Invalid option!";
            say "-------------------------------------";
            goto PICK_INITIAL_PIECE;
        }

        push @$picked_pieces,
          {
            'player_name' => $current_player->name,
            'piece'       => {
                'value' => $current_player->pieces->[$picked_piece_number],
                'piece_number' => $picked_piece_number
            }
          };
    }

    my $max_value_piece = get_starting_card_and_player($picked_pieces);
    change_players_order( $board, $max_value_piece->{player_name} );

    say "-------------------------------------";
    say "The order of the players: \n" . $board->stringify_players;

  PLAY_PIECES:
    foreach my $current_player ( @{ $board->players } ) {
        say "-------------------------------------";
        say $current_player->name . "'s turn:";
        say "Played pieces: " . $board->stringify_played_pieces;
        say "-------------------------------------";
        say $current_player->name
          . "'s pieces:"
          . $current_player->stringify_pieces;
        say "-------------------------------------";

        if ( !has_player_options( $board, $current_player ) ) {
            if ( $board->pieces_count == 0 ) {
                say "-------------------------------------";
                say "Player " . $current_player->name . " lost!";
                say "-------------------------------------";

                $board->remove_player_by_name( $current_player->name );
                goto AFTER_PLAY_PIECES;
            }
            else {
                say "-------------------------------------";
                say "You don't have options! Pick a piece.";
                say "-------------------------------------";
                pick_piece( $board, $current_player );
            }
        }
        else {
          PLAYER_MENU:
            my $cmd;
            if ( $board->pieces_count == 0 ) {
                say "-------------------------------------";
                say
"There are no available pieces on the board. Play one of your own pieces.";
                say "-------------------------------------";
                $cmd = '1';
            }
            else {
                say "-------------------------------------";
                say
"[1] Play a piece. \n[2] Pick a piece from the available pieces.";
                say "-------------------------------------";
                say "Your choice: ";
                chomp( $cmd = <STDIN> );
            }

            if ( $cmd eq '1' ) {
              PLAY_PIECE:
                say "-------------------------------------";
                say "Played pieces: " . $board->stringify_played_pieces;
                say "-------------------------------------";
                say $current_player->name
                  . "'s pieces:"
                  . $current_player->stringify_pieces;
                say "-------------------------------------";
              PICK_PIECE_TO_PLAY:
                say "Your choice: ";
                chomp( my $picked_piece = <STDIN> );

                my $last_piece_index = $current_player->pieces_count - 1;
                my $pattern          = join '|', 0 .. $last_piece_index;

                if ( $picked_piece !~ m/^(?:$pattern)$/ ) {
                    say "-------------------------------------";
                    say "Invalid option!";
                    say "-------------------------------------";
                    goto PICK_PIECE_TO_PLAY;
                }

              PICK_OPTION:
                say "-------------------------------------";
                say
"[1] Add to beginning of dominoes. \n[2] Add to end of dominoes.";
                say "-------------------------------------";
                say "Your option: ";
                chomp( my $playing_option = <STDIN> );

                if ( $playing_option eq '1' || $playing_option eq '2' ) {
                    my $piece_position =
                      $playing_option eq '1' ? 'beginning' : 'end';
                    try {
                        play_piece(
                            $board,        $current_player,
                            $picked_piece, $piece_position
                        );
                        say "-------------------------------------";
                        say "The piece has been added!";
                        say "-------------------------------------";
                    }
                    catch ( InvalidOperationException $e) {
                        say "$e";
                        goto PLAYER_MENU;
                    }
                }
                else {
                    say "-------------------------------------";
                    say 'Invalid option!';
                    say "-------------------------------------";
                    goto PICK_OPTION;
                }
            }
            elsif ( $cmd eq '2' ) {

                pick_piece( $board, $current_player );
                say "-------------------------------------";
                say $current_player->name
                  . "'s pieces:"
                  . $current_player->stringify_pieces;
                say "-------------------------------------";
            }
            else {
                say "-------------------------------------";
                say "Invalid option!";
                say "-------------------------------------";
                goto PLAYER_MENU;
            }
        }

        if ( $current_player->pieces_count == 0 ) {
            return $current_player->name;
        }
    }
  AFTER_PLAY_PIECES:
    if ( $board->pieces_count == 0 && all { !has_player_options( $board, $_ ) }
        @{ $board->players } )
    {
        say "-------------------------------------";
        say "GAME OVER!";
        say "-------------------------------------";
        my $sorted_players = $board->sort_players_by_score;
        say "Order: ";
        foreach ( @{$sorted_players} ) {
            say $_->name;
        }
        say "-------------------------------------";
        return $sorted_players->[0]->name;
    }
    elsif ( $board->players_count == 1 ) {
        return $board->players->[0]->name;
    }
    goto PLAY_PIECES;
}

sub pick_piece {
    my ( $board, $current_player ) = @_;
    say "Available pieces: ";

    $ENV{DEBUG}
      ? say $board->stringify_available_pieces
      : say $board->stringify_available_pieces( hidden => "1" );

    say "-------------------------------------";
    say $current_player->name
      . "'s pieces:"
      . $current_player->stringify_pieces;
    say "-------------------------------------";

  PICK_PIECE:
    say "Pick a piece:";
    my $picked_number = <STDIN>;
    chomp $picked_number;

    my $last_piece_index = $board->pieces_count - 1;

    my $pattern = join '|', 0 .. $last_piece_index;

    if ( $picked_number =~ m/^(?:$pattern)$/ ) {
        my $picked_piece =
          add_piece_to_player( $board, $current_player, $picked_number );
        say "-------------------------------------";
        say "The piece "
          . $picked_piece->to_string
          . " was added to your deck.";
        say "-------------------------------------";
    }
    else {
        say "-------------------------------------";
        say "Invalid option!";
        say "-------------------------------------";
        goto PICK_PIECE;
    }

}

1;
