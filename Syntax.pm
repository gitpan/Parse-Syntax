package Parse::Syntax;

use strict;
use vars qw($VERSION);

use Carp;
use Data::Dumper;

$VERSION = '0.01';

# - initialiser method
sub _init {
    my $self = shift;

    croak "Syntax folder couldn't be located at $self->{stx_folder}" unless -e $self->{stx_folder};

    local $/ = "\n";
    local $! = undef;

    $self->{_filename} = $self->{stx_folder}.'/'.$self->{lang}.'.stx';

    open SYNTAX, "<".$self->{_filename} or croak "$self->{_filename} couldn't be opened, $!";


    my ($keyword, $value);

    while (<SYNTAX>) {
        next if /^\n/;
        chomp;

        if (/^#KEYWORD=(.+)/) {
            $keyword = uc($1);
            $keyword =~ s/\W/_/g;
        } elsif (/^#([^=]+)=(.*)/) {
            next unless $2;
            push @{ $self->{$1} }, $self->escapeHTML($2);
        } else {
            push @{ $self->{KEYWORD}{$keyword} }, $_ ;
        }
    }
    close SYNTAX;
return 1;
}


# - constructor method
sub new {
    my $invocer = shift;
    my $class = ref($invocer) || $invocer;
    my $self = {
        stx_folder => 'Stx',
        lang       => 'Perl',
        @_,
    };
    bless $self, $class;

    $self->_init();
return $self;
}



sub regexCompiler {
    my ($self, $kw) = @_;
    my $big_kw = join '|', @{ $kw };
    return qr/$big_kw/;

}




sub parse {
    my ($self, $data) = @_;
    $data = $self->escapeHTML($data);
    # -parsing KEYWORDs
    for (keys %{$self->{KEYWORD}}) {
        my $pattern = $self->regexCompiler( $self->{KEYWORD}{$_} );
        # - don't match in in the middle of the word
        $data =~ s/\b($pattern)\b/<span class="$_">$1<\/span>/g;
    }

    # -parsing LINECOMMENTs
    {
        my $pattern = $self->regexCompiler($self->{LINECOMMENT});
        $data =~ s/([^\\]($pattern).*)/<span class="LINECOMMENT">$1<\/span>/g;
    };

    # -parsing QUOTATIONs
    {
        my $pattern = $self->regexCompiler($self->{QUOTATION});
        $data =~ s/(($pattern).*?\2)/<span class="QUOTATION">$1<\/span>/g;
    };

return $data;
}




sub escapeHTML {
    my ($self, $data) = @_;

    # why don't we convers tabs to spaces as well, huh?
    $data =~ s/\t/    /g;


    # I am sure main bugs tend to arise due to the wrong escaping
    # So I might modify the following list further, I guess.
    # Actually, if I pass this part of the module to itself, it faces
    # problems. Quotations get messed up :-(
    my %_char = ( "&" => "&#38;", "#" => "&#35;", ">" => "&#62;", "<" => '&#60;',
        '^' => '&#94;', '$' => '&#36;', '"' => '&#34;', "'" => "&#39;",
    );

    $data =~ s/([&><^\$#'"])/$_char{$1}/g;

    return $data;
}





sub dump {
    my ($self, $fh) = @_;

    open DUMP, ">"."Stx.dmp" or die $!;

    print DUMP Dumper($self);

    close DUMP;

}



1;


=pod

=head1 Name

Parse::Syntax - Perl extension for Syntax-highlighting progamming languages

=head1 Synopsis

    use Parse::Syntax;

    my $stx = new Parse::Syntax(stx_folder=>'/path/to/stx_folder', lang=>'Perl');

    print $stx->parse(<<'END_OF_TEXT'
    #!/usr/bin/perl -w
    use strict;

    if (foo eq bar) {
        print "You're screwed\n";
    } else {
        print "That's the way it is\n";
    }
    exit 0;

END_OF_TEXT

    );


=head1 Description

THIS IS AN ALPHA RELEASE. Anything is subject to change and no backward compatibility
is guranteed (yet)

This documentation refers to version 0.01 of Parse::Syntax. Parse::Syntax class
is intended to be used in on-line forums and discussion boards (such as perlguru.com?).
It highlights the syntax of any programming lanuage provided that it has *.stx file
for a spesific language it's expected to parse. Parse::Syntax does not base
on any other modules, and rely mainly on Perl's powerfull regex engine.

Main method you need to be aware of is I<parse()> method, which receives one
argument, which should be either an expression or a variable which holds the
expression to be parsed/highlighted. As of version 0.01, the argument should be
only a scalar value. I relise that it whould be nice if we could pass a reference
to filehandle and get the method to work on the contents of the file. Well,
this feature is comming in the next version. For more detailed list of future
features refer to L<"Todo"> section

=head2 How it works

For the class to perform as expected, you need to provide it with a *.stx file,
which I will refer to as I<grammar> throughout the documentation.
When you create the object with L<new()> method, Parse::Syntax scans through the
grammar file, and constructs an annonymous hash with all the available key/value pairs.
Once you pass the expression to L<parse()>, it calls C<regexCompiler> method internally
which in turn compiles and returns a precompiles pattern (using qr// operator).
The rest is nothing but matching and substitution. As to their color representation
I have a bad news (well, I am not sure how bad it is tho). It relies on CSS (Style Sheet)
classes

To understand which classes the parser expects, keep reading. Hopefully, I'm
not going to keep it as a secret

=head2 Format of the Grammar file

For the grammar file I used *.stx files from my favourite EditPlus 2.10c by
ES-Computing. So you can grab one of the *.stx files from your copy of EditPlus
and get it to work with *some* minor changes. A standard grammar file that
Parse::Syntax expects to deal with looks something like this:


    #DELIMITER=,(){}[]-+*/=~!&|<>?:;.
    #QUOTATION='
    #QUOTATION="
    #CONTINUE_QUOTE=n
    #LINECOMMENT=#
    #LINECOMMENT=
    #COMMENTON=
    #COMMENTOFF=
    #COMMENTON=
    #COMMENTOFF=
    #ESCAPE=\
    #CASE=y
    #PREFIX=$
    #PREFIX=@
    #PREFIX=%
    #SUFFIX=

    #KEYWORD=Reserved words
    continue
    do
    else
    elsif
    for
    foreach
    .......

    #KEYWORD=Built-in functions
    abs
    accept
    alarm
    atan2
    bind
    binmode
    bless
    .....

You can add more and more #KEYWORD fields to the above grammar file if you wish so.
Forexample, suppose I want standard Perl pragmas and Standard Classes to be highlighted as
well. In my text editor, I would add the following lines to the in addition to the
above:

    #KEYWORD=Pragmas
    strict
    warnings
    ...

    #KEYWORD=Standard Classes
    Autoloader
    Autosplit
    CGI
    AnyDBM_File
    ......

Above I chose I<Pragmas> and I<Standard Classes> as the name to the KEYWORD section.
If I was in a bad mood I could name those I<Compiler Directives> and I<Predefined Modules>
instead. For Parse::Syntax it doesn't make any difference. But, there is a small "but".
Those keywords are used as Style Sheet classes. Forexample, following expression:

    use AnyDBM_File;

would be parsed as following:

    <span class="RESERVED_WORDS">use</span> <span class="STANDARD_CLASSES">AnyDBM_File</span>

Of course, you cannot see this unless you view the source of the page in your browser.
As you see, it converts the keyword names to uppercase and replaces spaces with underscore.
It also implies that you need to provide that page with corresponding Style Sheet classes:

    .RESERVED_WORDS {
        color:       Blue;
    }

    .STANDARD_CLASSES {
        color:       #990000;
    }

At this point I realise that Notion of CSS (Cascading Style Sheets) might sound
pretty fearsome for an average Perl programmer. I will try  to take this wight off
your shoulders hopefully in the next release. Please refer to L<"Todo"> section for 
more upcomming features. Remember though, NO HTML 4.0 WITHOUT CSS!!!


=head1 Methods

=over 4

=item C<new()>

L<new()> method return creates and returns instance of the Parse::Syntax class.
It take following arguments:

=over 2

=item C<stx_folder> => '/stx/files/are/here'

Designates a folder from whish the Parse::Syntax should locate *.stx files

=item C<lang> => 'Perl'

Tells the parser which language's *.stx file to use to parse the expression/chunk of code

=back

=item C<parse()>

Main method which parses the expression.

=item C<set_level()> I<not implemented as of version 0.01>

L<set_level()> method enables you to set the level of hightlighting and
goes from 0 for none, up to 3 for maximum

=back


=head1 Todo

Listing of the features I am planning to add in the next release

=over 4

=item * Indentation

=item * More flexibility in setting highlighting level

=item * Ability to choose between CSS and and setting the colors right in the grammar file.

I think this would be nice; seperate highlighting for each grammar file!!! 
Plus, no CSS hustle for those who cannot get along well with them yet

=item * More polimorphic L<"parse()"> method

Wouldn't it be  great if we could pass filehandle to L<"parse()"> and get it to operate on the 
contents of the file? How about redirecting standard output to a file?

=item * Is there such extension for Perl/Tk? 

I am woundering how much effort it would require to make it compatible with Tk.

=back

If you have any other suggestions and/or want to contribute some code 
to Parse::Syntax, you are more than wellcome. Send me an email to sherzodr@ultracgis.com
and we can talk about it


=head1 Bugs

Do you think I could fill this section in the next realease and keep this one clean?
Cool. I knew you'd let me do that :-)

=head1 Author

Sherzod Ruzmetov a.k.a sherzodR, sherzodr@ultracgis.com

=head1 Copyright

Copyright 2001, Sherzod Ruzmeto.  All rights reserved.
This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
Bug reports and comments to sherzodr@ultracgis.com

=head1 See Also

Parse::RecDescent, Parse::Token, Parse::yapp, CGI

=cut
