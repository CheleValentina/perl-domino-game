#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';

use Model::Board;
use Game;
use Exceptions;
use Test::More tests => 36;
use Test::Exception;
use Data::Dumper;
use List::Util qw(all);
use Time::HiRes qw(gettimeofday tv_interval);
use 5.010;

my $start_time = [gettimeofday];

throws_ok { Model::Player->new( name => "" ) } 'ValidationException',
  'PlayerNameNotEmpty';

my $player1 = Model::Player->new( name => "Player 1 Wrong" );

$player1->set_name('Player 1');
is( $player1->name, 'Player 1', 'PlayerNameWasChanged' );

my $player2 = Model::Player->new( name => "Player 2" );
my $player3 = Model::Player->new( name => "Player 3" );
my $player4 = Model::Player->new( name => "Player 4" );
my $player5 = Model::Player->new( name => "Player 5" );

my $board = Model::Board->new;
$board->add_player($player1);
throws_ok { $board->validate_minimum_players } 'SmallObjectNumberException',
  'ThrowErrorWhenLessThanTwoPlayersOnBoard';
is( $board->players_count, 1, 'CorrectNumberOfPlayersOnBoard' );

$board->add_player($player1);
throws_ok { $board->validate_players } 'NonUniqueObjectException',
  'ThrowErrorWhenTwoPlayersWithSameName';
is( $board->players_count, 1, 'CorrectNumberOfPlayersOnBoard' )
  ;    # Check if the player with same name was not added
is( $board->players->[0], $player1, 'CorrectPlayerWasAdded' );

$board->add_player($player2);
is( $board->players_count, 2, 'CorrectNumberOfPlayersOnBoard' );

$board->add_player($player3);
$board->add_player($player4);
$board->add_player($player5);
throws_ok { $board->validate_players } 'BigObjectNumberException',
  'ThrowErrorWhenMoreThanFivePlayersOnBoard';

my @initial_deck  = @{ $board->available_pieces };
my @shuffled_deck = @{ fisher_yates_shuffle( \@initial_deck ) };
@initial_deck = @{ $board->available_pieces };
my @second_shuffled_deck = @{ fisher_yates_shuffle( \@initial_deck ) };

ok( !are_two_arrays_of_cards_equal( $board->available_pieces, \@shuffled_deck ),
    'TheDeckWasShuffled' );
ok(
    !are_two_arrays_of_cards_equal(
        $board->available_pieces, \@second_shuffled_deck
    ),
    'TheDeckWasShuffled'
);
ok( !are_two_arrays_of_cards_equal( \@shuffled_deck, \@second_shuffled_deck ),
    'TheDeckWasShuffled' );

is( $board->pieces_count, 28, 'InitialNumberOfPieces' );

$board->remove_player_by_name('Player 4');
is( $board->players_count, 3, 'CorrectNumberOfPlayers' );

my $added_piece = add_piece_to_player( $board, $player1, 0 );
is( $player1->get_score, 0, 'PlayerScore' );

ok( $added_piece->upper_dots == 0 && $added_piece->lower_dots == 0,
    'CorrectAddedPiece' );
ok( $player1->pieces_count == 1 && $player1->pieces->[0] == $added_piece,
    'PieceAddedToPlayer' );
ok(
    $board->pieces_count == 27
      && !is_element_contained_by_array( $added_piece,
        $board->available_pieces ),
    'PieceRemovedFromBoard'
);

add_piece_to_player( $board, $player2, 0 );
is( $player2->get_score, 1, 'PlayerScore' );

my $picked_pieces = [
    {
        'player_name' => $player1->name,
        'piece'       => {
            'value'        => $player1->pieces->[0],
            'piece_number' => 0
        }
    },
    {
        'player_name' => $player2->name,
        'piece'       => {
            'value'        => $player2->pieces->[0],
            'piece_number' => 0
        }
    }
];
my $max_value_piece = get_starting_card_and_player($picked_pieces);
is( $max_value_piece, $picked_pieces->[0], 'CorrectStartingPiece' )
  ;    # The first piece is a double, [0][0]

add_piece_to_player( $board, $player3, 0 );
my $sorted_players = $board->sort_players_by_score;
is( $sorted_players->[0], $player3, 'CorrectScoreOrder' );
is( $sorted_players->[1], $player2, 'CorrectScoreOrder' );
is( $sorted_players->[2], $player1, 'CorrectScoreOrder' );

push @$picked_pieces,
  {
    'player_name' => $player3->name,
    'piece'       => {
        'value'        => $player3->pieces->[0],
        'piece_number' => 0
    }
  };
shift @$picked_pieces;

$max_value_piece = get_starting_card_and_player($picked_pieces);

# The first piece should be the one that the third player has picked, since the double was removed
is( $max_value_piece, $picked_pieces->[1], 'CorrectStartingPiece' );

change_players_order( $board, $player2->name );
my $correct_order = [ $player2, $player3, $player1 ];
ok(
    (
        all { $board->players->[$_]->name eq $correct_order->[$_]->name }
          0 .. 2
    ),
    'CorrectPlayersOrder'
);

is( has_player_options( $board, $player1 ), 1, 'ThePlayerHasOptions' );
play_piece( $board, $player1, 0, 'beginning' );
is( $board->played_pieces_count,           1 );
is( $player1->pieces_count,                0 );
is( $board->played_pieces->[0]->to_string, '[0][0]' );

play_piece( $board, $player2, 0, 'beginning' );
is( $board->played_pieces_count,           2 );
is( $board->played_pieces->[0]->to_string, '[1][0]' );

is( has_player_options( $board, $player3 ), 1, 'ThePlayerHasOptions' );
throws_ok { play_piece( $board, $player3, 0, 'beginning' ) }
'InvalidOperationException';
play_piece( $board, $player3, 0, 'end' );
is( $board->played_pieces->[-1]->to_string, '[0][2]' );

add_piece_to_player( $board, $player4, 5 );    # Add piece [1][2]
$board->add_player($player4);

play_piece( $board, $player4, 0, 'end' );
is( $board->played_pieces->[-1]->to_string, '[2][1]' );

add_piece_to_player( $board, $player4, 23 );
add_piece_to_player( $board, $player4, 22 );
add_piece_to_player( $board, $player4, 21 );
add_piece_to_player( $board, $player4, 20 );
is( has_player_options( $board, $player3 ), 0, 'ThePlayerDoesNotHaveOptions' );

done_testing();
my $runtime = tv_interval( $start_time, [gettimeofday] );
diag("Runtime: $runtime");
exit();
