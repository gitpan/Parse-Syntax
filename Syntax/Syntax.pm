package Parse::Syntax;

use strict;
use vars qw($VERSION);
use Carp;

$VERSION = '0.01';

# - initialiser method
sub _init {
	my $self = shift;
	$self->{_stx_folder} = $SYNTAX_FOLDER;
	
	carp "Syntax folder couldn't be located at $self->{_stx_folder}" unless -e $self->{_stx_folder};

	open SYNTAX, '<'.$self->{_stx_folder} or return 0;

	while (<SYNTAX>) {
		# do smt here
	}

	close SYNTAX;


	return 1;
}



# - constructor method
sub new { 
	my $invocer = shift;
	my $class = ref($invocer) || $invocer;
	my $self = { @_ };
	
	bless $self, $class;

	$self->_init();

	return $self;
}










1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Parse::Syntax - Perl extension for Syntax-Higlighting programming *any* languages. 

=head1 SYNOPSIS

  use Parse::Syntax;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Parse::Syntax was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

Sherzod Ruzmetov a.k.a sherzodR, sherzodr\@ultracgis.com

=head1 SEE ALSO

perl(1).

=cut
