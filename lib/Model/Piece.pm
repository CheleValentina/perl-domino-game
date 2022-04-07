package Model::Piece;
use Moose;

has upper_dots => (
    documentation => q{The piece's upper part},
    is            => "rw",
    required      => 1
);
has lower_dots => (
    documentation => q{The piece's lower part},
    is            => "rw",
    required      => 1
);

=pod
=item get_total_dots()

Returns an integer representing the total number of dots on the piece.

=cut

sub get_total_dots {
    my ($self) = @_;

    return $self->upper_dots + $self->lower_dots;
}

=pod
=item to_string()

Returns the piece as a string.

=cut

sub to_string {
    my ($self) = @_;

    return '[' . $self->upper_dots . '][' . $self->lower_dots . ']';
}

=pod
=item to_string_hidden()

Returns the hidden piece as a string.

=cut

sub to_string_hidden {
    my ($self) = @_;

    return '[?][?]';
}

=pod
=item is_double()

Checks if the piece is a double

=cut

sub is_double {
    my ($self) = @_;

    return $self->upper_dots == $self->lower_dots;
}

=pod
=item equals($other)

Returns true if the current piece equals the given piece.

$other is the piece that is compared with the current piece

=cut

sub equals {
    my ( $self, $other ) = @_;

    $self->upper_dots == $other->upper_dots
      && $self->lower_dots == $other->lower_dots;
}

=pod

    Flips the piece by changing its lower_dots into its upper_dots and vice versa.

=cut

sub change_sides {
    my ($self) = @_;

    my $upper_dots = $self->upper_dots;
    my $lower_dots = $self->lower_dots;
    $self->upper_dots($lower_dots);
    $self->lower_dots($upper_dots);
}

1;
