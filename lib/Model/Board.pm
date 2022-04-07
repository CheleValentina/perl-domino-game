package Model::Board;

use Moose;
use Moose::Util::TypeConstraints;
use List::MoreUtils qw(uniq);
use Array::Utils qw(array_diff);
use Data::Dumper;
use Test::More;

use Model::Player;
use Model::Piece;

has players => (
    documentation => q{The players on the board},
    is            => "rw",
    isa           => 'ArrayRef[Model::Player]',
    traits        => ['Array'],
    handles       => {
        add_player    => 'push',
        players_count => 'count'
    },
    default => sub { [] },
);

has available_pieces => (
    documentation => q{The available (not taken) pieces on the board},
    is            => "rw",
    isa           => 'ArrayRef[Model::Piece]',
    traits        => ['Array'],
    builder       => '_build_initial_deck_of_pieces',
    handles       => {
        add_piece    => 'push',
        pieces_count => 'count'
    },
    writer    => "set_pieces",
    predicate => 'has_available_pieces'
);

has played_pieces => (
    documentation => q{The pieces that were played},
    is            => "rw",
    isa           => 'ArrayRef[Model::Piece]',
    traits        => ['Array'],
    handles       => {
        add_piece_end       => 'push',
        add_piece_beginning => 'unshift',
        played_pieces_count => 'count'
    },
    default => sub { [] },
);

=pod
=item validate_minimum_players()

Throws a SmallObjectNumberException if there are not minimum 2 players on the board.

=cut

sub validate_minimum_players {
    my ($self) = @_;

    SmallObjectNumberException->throw(
        error => 'There should be at least 2 players!' )
      if $self->players_count < 2;
}

=pod
=item validate_players()

Throws a NonUniqueObjectException if there are two players with the same name.
Throws a BigObjectNumberException if there are more than 5 players in the game and removes the last added player.

=cut

sub validate_players {
    my ($self) = @_;

    pop @{ $self->players }
      && NonUniqueObjectException->throw(
        error => 'There shouldn\'t be two players with the same name!' )
      if scalar @{ _get_players_names_array( $self->players ) } !=
      scalar uniq @{ _get_players_names_array( $self->players ) };

    pop @{ $self->players }
      && BigObjectNumberException->throw(
        error => 'There should be maximum 4 players!' )
      if $self->players_count > 4;
}

=pod
=item stringify_players()

Returns a string with all the names of the players.

=cut

sub stringify_players {
    my ($self) = @_;

    my $string = '';

    foreach ( @{ $self->players } ) {
        $string .= $_->name . "\n";
    }

    return $string;
}

=pod
=item stringify_available_pieces(%args)

Returns a string with all the available pieces.

$args{hidden} should be 1 if the returned string has the pieces shown upside down and 0 otherwise

=cut

sub stringify_available_pieces {
    my ( $self, %args ) = @_;

    my $hidden = $args{hidden};

    my $string      = '';
    my $card_number = 0;

    foreach ( @{ $self->available_pieces } ) {
        $string .= $card_number++ . ": ";
        $string .= !$hidden ? $_->to_string : $_->to_string_hidden;
        $string .= " ";
    }

    return $string;
}

=pod
=item stringify_played_pieces()

Returns a string with all the played pieces.

=cut

sub stringify_played_pieces {
    my ($self) = @_;

    my $string = '';
    foreach ( @{ $self->played_pieces } ) {
        $string .= $_->to_string . " ";
    }

    return $string;
}

=pod
=item remove_piece_by_index($piece_index)

Removes a piece from the available pieces by its index.

$piece_index is the index of the piece that has to be removed

=cut

sub remove_piece_by_index {
    my ( $self, $piece_index ) = @_;

    splice( @{ $self->available_pieces }, $piece_index, 1 );
}

=pod
=item remove_player_by_name($player_name)

Removes a player from board by its name.

$player_name is the name of the player that has to be removed

=cut

sub remove_player_by_name {
    my ( $self, $player_name ) = @_;

    @{ $self->players } = grep $_->name ne $player_name, @{ $self->players };
}

=pod
=item _build_initial_deck_of_pieces()

Builds the initial deck of 28 pieces.

=cut

sub _build_initial_deck_of_pieces {
    my $pieces;

    foreach my $upper_counter ( 0 .. 6 ) {
        foreach my $lower_counter ( $upper_counter .. 6 ) {
            push @$pieces,
              (
                Model::Piece->new(
                    upper_dots => $upper_counter,
                    lower_dots => $lower_counter
                )
              );
        }
    }
    return $pieces;
}

=pod
=item _get_players_names_array($players)

Returns an array with all the names of the players.

$players is a list of players

=cut

sub _get_players_names_array {
    my ($players) = @_;

    my $names;

    foreach ( @{$players} ) {
        push @$names, $_->name;
    }

    return $names;
}

=pod
=item sort_players_by_score()

Sorts the players in descending order by their score.

=cut

sub sort_players_by_score {
    my ($self) = @_;

    my @sorted_players =
      sort { $b->get_score cmp $a->get_score } @{ $self->players };

    return \@sorted_players;
}

1;
