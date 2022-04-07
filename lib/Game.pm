package Game;
use strict;
use warnings;
use base 'Exporter';
use List::Util qw(all);
use Try::Tiny;
use Test::More;
use Data::Dumper;
our @EXPORT =
  qw(fisher_yates_shuffle add_piece_to_player get_starting_card_and_player change_players_order
  is_element_contained_by_array are_two_arrays_of_cards_equal play_piece has_player_options);

=pod
=item fisher_yates_shuffle(@array)

Returns a shuffled array by using the Fisher-Yates method

@array is the array that should be shuffled

=cut

sub fisher_yates_shuffle {
    my ($array) = @_;

    for ( my $i = @$array ; --$i ; ) {
        my $j = int rand( $i + 1 );
        next if $i == $j;
        @$array[ $i, $j ] = @$array[ $j, $i ];
    }

    return $array;
}

=pod
=item add_piece_to_player($board, $player, $picked_number)

Adds a piece to a player and removes it from the board

$board is the current board
$player is the player that is getting the piece
$picked number is the index of the card that will be added to the player

=cut

sub add_piece_to_player {
    my ( $board, $player, $picked_number ) = @_;

    my $picked_piece = $board->available_pieces->[$picked_number];

    $player->add_piece($picked_piece);
    $board->remove_piece_by_index($picked_number);

    $picked_piece;
}

=pod
=item get_starting_card_and_player($picked_pieces)

Returns the player and the card that will start the game. The card should either be the biggest double or have
the biggest number of points

$picked_pieces is a hash containing the player that picked the piece, the actual piece and the piece index
from the payer's deck of cards

=cut

sub get_starting_card_and_player {
    my ($picked_pieces) = @_;

    my $max_value_piece;

    foreach (@$picked_pieces) {
        if ( !defined $max_value_piece ) {
            $max_value_piece = $_;
        }

        # Check if the card is a double
        elsif ( $_->{'piece'}{'value'}->is_double ) {

            # Check if the current max value piece is also a double
            if ( $max_value_piece->{'piece'}{'value'}->is_double ) {
                $max_value_piece = $_
                  if $max_value_piece->{'piece'}{'value'}->upper_dots <
                  $_->{'piece'}{'value'}->upper_dots;
            }
            else {
                $max_value_piece =
                  $_;    # The double has priority over other cards
            }
        }

        # If the card is not a double
        else {
            $max_value_piece = $_
              if !$max_value_piece->{'piece'}{'value'}->is_double
              && $max_value_piece->{'piece'}{'value'}->get_total_dots <
              $_->{'piece'}{'value'}->get_total_dots;
        }
    }

    return $max_value_piece;
}

=pod
=item change_players_order($board, $player_name)

Changes the order of the players on the board

$board is the current board
$player_name is the name of the player that will start the game

=cut

sub change_players_order {
    my ( $board, $player_name ) = @_;

    my $first_array  = [];
    my $second_array = [];
    my $found        = 0;

    for my $player ( @{ $board->players } ) {
        if ( $player->name ne $player_name && $found == 0 ) {
            push @$first_array, $player;
        }
        elsif ( $player->name eq $player_name ) {
            push @$second_array, $player;
            $found = 1;
        }
        else {
            push @$second_array, $player;
        }
    }

    push @$second_array, @$first_array;
    $board->players($second_array);
}

=pod
=item are_two_arrays_of_cards_equal($first_array, $second_array)

Checks if two arrays contain the same cards, in the same order.

$first_array is the first array of cards
$second_array is the second array of cards

=cut

sub are_two_arrays_of_cards_equal {
    my ( $first_array, $second_array ) = @_;

    all {
        scalar @$first_array == scalar @$second_array
          && $first_array->[$_]->equals( $second_array->[$_] )
    } 0 .. $#$first_array;
}

=pod
=item is_element_contained_by_array($element, $array)

Checks if an array contains a given element.

$element is the given element that is searched
$array is the array where the element is searched

=cut

sub is_element_contained_by_array {
    my ( $element, $array ) = @_;

    my %params = map { $_ => 1 } @$array;
    exists( $params{$element} );
}

=pod
=item play_piece($board, $player, $piece_index, $place, $verify)

Adds a piece from a player's deck of pieces on the playing table.
Throws InvalidOperationException if the piece does not match with the piece that already is on the table.

$board is the current playing board
$player is the player who plays a piece
$piece_index is the index of the piece that is played from the player's deck
$place is the place on the table where the piece should be added; can be 'beginning' or 'end
$verify is a flag used when the card is not actually played, but only verified if it can be played

=cut

sub play_piece {
    my ( $board, $player, $piece_index, $place, $verify ) = @_;

    my $played_piece      = $player->pieces->[$piece_index];
    my $all_played_pieces = $board->played_pieces;

    if ( $board->played_pieces_count == 0 ) {
        if ( !defined $verify ) {
            $board->add_piece_end($played_piece);
            $player->remove_piece($piece_index);
        }
    }
    else {
        if ( $place eq 'beginning' ) {
            if ( $all_played_pieces->[0]->upper_dots ==
                $played_piece->upper_dots )
            {
                if ( !defined $verify ) {
                    $played_piece->change_sides;
                    $board->add_piece_beginning($played_piece);
                    $player->remove_piece($piece_index);
                }
            }
            elsif ( $all_played_pieces->[0]->upper_dots ==
                $played_piece->lower_dots )
            {
                if ( !defined $verify ) {
                    $board->add_piece_beginning($played_piece);
                    $player->remove_piece($piece_index);
                }
            }
            else {
                InvalidOperationException->throw( error => "Cannot add piece" );
            }
        }
        else {
            if ( $all_played_pieces->[-1]->lower_dots ==
                $played_piece->upper_dots )
            {
                if ( !defined $verify ) {
                    $board->add_piece_end($played_piece);
                    $player->remove_piece($piece_index);
                }
            }
            elsif ( $all_played_pieces->[-1]->lower_dots ==
                $player->pieces->[$piece_index]->lower_dots )
            {
                if ( !defined $verify ) {
                    $played_piece->change_sides;
                    $board->add_piece_end($played_piece);
                    $player->remove_piece($piece_index);
                }
            }
            else {
                InvalidOperationException->throw( error => "Cannot add piece" );
            }
        }
    }
}

=pod
=item has_player_options($board, $player)
Checks if a player has pieces that can be played (they match one of the already played pieces).

$board is the current board
$player is the player that is being checked

=cut

sub has_player_options {
    my ( $board, $player ) = @_;

    my $found = 0;

    foreach my $piece_index ( 0 .. $player->pieces_count ) {
        foreach my $position ( 'beginning', 'end' ) {
            try {
                play_piece( $board, $player, $piece_index, $position, 1 );
                $found = 1;
            };
            return 1
              if $found == 1;
        }

        return 1
          if $found == 1;
    }

    return 0;
}

1;
