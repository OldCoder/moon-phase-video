#!/usr/bin/env perl
# moonphase2avi.pl - Creates a moon-phase AVI or an animated GIF
# License:  Creative Commons Attribution-NonCommercial-ShareAlike 3.0
# Revision: 120709

#---------------------------------------------------------------------
#                           important note
#---------------------------------------------------------------------

# This program is  provided on an  AS IS basis with ABSOLUTELY NO WAR-
# RANTY. The entire risk as to the quality and performance of the pro-
# gram is with you. Should the program prove defective, you assume the
# cost of all necessary  servicing, repair or correction.  In no event
# will any of the developers, or any other party,  be liable to anyone
# for damages arising out of  use of the program,  or inability to use
# the program.

#---------------------------------------------------------------------
#                              overview
#---------------------------------------------------------------------

                                # 'END...' may be single-quoted here
my $DOCUMENTATION = << 'END_OF_DOCUMENTATION';
__META_NAME__ rev. __META_REVISION__
- Creates a moon-phase video clip

Recommended: Remove the ".pl"  filename extension and set file permis-
sions to 755 octal.

Usage:  __META_NAME__ --avi         # Make high-quality AVI
        __META_NAME__ --gif         # Make animated GIF instead
        __META_NAME__ --needs       # List software requirements
        __META_NAME__ --license     # Show license information

"--avi" creates  an  AVI file  named "moonphase.avi" that displays one
month in the life of  the Moon.  The AVI file is MPEG4-encoded. You'll
need  write  access to  the  current directory and  about 8 MB of disk
space. However, the AVI file is only about 210 KB in size.

"--gif" is similar, but it creates a low-resolution  animated  GIF in-
stead of an AVI.

For software requirements or license information, specify "--needs" or
"--license".
END_OF_DOCUMENTATION

#---------------------------------------------------------------------
#                          base module setup
#---------------------------------------------------------------------

require 5.8.1;
use strict;
use Carp;
use warnings;
                                # Trap warnings
$SIG {__WARN__} = sub { die @_; };

#---------------------------------------------------------------------
#                           basic constants
#---------------------------------------------------------------------

use constant ZERO  => 0;        # Zero
use constant ONE   => 1;        # One
use constant TWO   => 2;        # Two

use constant FALSE => 0;        # Boolean FALSE
use constant TRUE  => 1;        # Boolean TRUE

#---------------------------------------------------------------------
#                         program parameters
#---------------------------------------------------------------------

my $PROGNAME = 'moonphase2avi'; # Program name (should be one word)
my $REVISION = '120709';        # Revision string

#---------------------------------------------------------------------

# AVI-file parameters:

my $AVI_FPS       =  20;        # Frames per second (10 to 30)
my $AVI_NUMFRAMES = 200;        # No. of frames (100 to 300)
                                # Output    -file name
my $AVI_OFNAME    = 'moonphase.avi';
                                # Temporary -file name
my $AVI_TFNAME    = "temp$$.tmp";
my $AVI_WIDTH     = 320;        # Image width (in pixels)

#---------------------------------------------------------------------

# GIF-file parameters:

my $GIF_FPS       =  10;        # Frames per second (10 to 30)
my $GIF_NUMFRAMES = 150;        # No. of frames (100 to 300)
                                # Output    -file name
my $GIF_OFNAME    = 'moonphase.gif';
                                # Temporary -file name
my $GIF_TFNAME    = "temp$$.gif";
my $GIF_WIDTH     = 120;        # Image width (in pixels)

my $IGNUMCOLORS   =  28;        # Max no. of colors in final GIF file

#---------------------------------------------------------------------
#                            main routine
#---------------------------------------------------------------------

sub Main
{
    my $cmd;                    # Shell-level command string
    my $str;                    # Scratch

    my $cmderr  = FALSE;        # Flag: Command-line error
    my $is_avi  = TRUE;         # Flag: Make AVI (as opposed to GIF)
    my $run     = FALSE;        # Flag: Proceed with main operation

    my $license = FALSE;        # Flag: Saw "--license" switch
    my $needs   = FALSE;        # Flag: Saw "--need(s)" switch

#---------------------------------------------------------------------
# Initial setup.

                                # Note: STDERR must be set first here
    select STDERR; $| = ONE;    # Force STDERR flush on write
    select STDOUT; $| = ONE;    # Force STDOUT flush on write

#---------------------------------------------------------------------
# Process the command line.

    for my $arg (@ARGV)         # Process all  arguments
    {                           # Process next argument
        if ($arg =~ s@^-+(make|)avi\w*\z@@i)
            { $is_avi = TRUE  ; $run = TRUE; }

        if ($arg =~ s@^-+(make|)gif\w*\z@@i)
            { $is_avi = FALSE ; $run = TRUE; }

        $license  = TRUE  if $arg =~ s@^-+lic\w*\z@@i;
        $needs    = TRUE  if $arg =~ s@^-+need\w*\z@@i;
        $needs    = TRUE  if $arg =~ s@^-+require\w*\z@@i;
        $run      = TRUE  if $arg =~ s@^-+run\w*\z@@i;
        $cmderr   = TRUE  if length $arg;
    }

#---------------------------------------------------------------------
# Handle "--license" and/or "--need(s)" switches.

    if ($license || $needs)
    {
        print << 'END';

Requirements: This program requires "moonphasepic" (a related program)
and "povray"  3.6.1+.  Additionally, AVI output mode requires "mencod-
er".  GIF output mode  requires  "gifsicle" 1.48+, "imagemagick" 6.3+,
and "intergif" 6.15+.

License:  This program is licensed under Creative Commons Attribution-
NonCommercial-ShareAlike 3.0.

END
        exit ONE;
    }

#---------------------------------------------------------------------
# If necessary, print usage text and exit.

    if ($cmderr || ($run == FALSE))
    {
        $DOCUMENTATION =~ s@^\s+@@s;
        $DOCUMENTATION =~ s@(__META_REVISION__)\n(-)@$1 $2@;
        $DOCUMENTATION =~ s@__META_NAME__@$PROGNAME@g;
        $DOCUMENTATION =~ s@__META_REVISION__@$REVISION@g;
        $DOCUMENTATION =~ s@\s*\z@\n@s;

        print "\n", $DOCUMENTATION, "\n";
        exit ONE;
    }

#---------------------------------------------------------------------
# Check external programs.

                                # Build list of programs needed
    my @progs = ();
       @progs = qw (mencoder) if $is_avi;
       @progs = qw (convert gifsicle intergif) unless $is_avi;
    push (@progs, 'povray');

    for my $prog (@progs)       # Check all  programs
    {                           # Check next program
        $str =  `which "$prog" 2>&1`;
        $str =  "" unless defined $str;
        $str =~ s@\n.*\z@@s;
                                # Error if program is missing
        die "Error: Operation needs the program $prog\n"
            unless (-f $str) && (-x $str);
    }

#---------------------------------------------------------------------
# Check for rest of package.

                                # Build list of remaining files
    my @files = qw (albedo_simp750.jpg moonphasepic.pl);

    for my $file (@files)       # Check all  files
    {                           # Check next file
        next if -f $file;       # If file exists, skip to next one
                                # File list as a string
        $str = join ' ', @files;

        print STDERR << "END";  # Print error message
Error: This program should be run in the directory that contains:
$str
END
        exit ONE;               # Error exit
    }

#---------------------------------------------------------------------
# Additional setup.

                                # Move some of the parameters
    my $FPS       = $is_avi ? $AVI_FPS       : $GIF_FPS         ;
    my $NUMFRAMES = $is_avi ? $AVI_NUMFRAMES : $GIF_NUMFRAMES   ;
    my $OFNAME    = $is_avi ? $AVI_OFNAME    : $GIF_OFNAME      ;
    my $TFNAME    = $is_avi ? $AVI_TFNAME    : $GIF_TFNAME      ;
    my $WIDTH     = $is_avi ? $AVI_WIDTH     : $GIF_WIDTH       ;

                                # Compute image height (in pixels)
    my $HEIGHT = int (($WIDTH * 0.75) + 0.5);

                                # Check "write" access
    die "Error: Can't write to current directory: $!\n"
        unless open (OFD, ">$TFNAME") &&
            close (OFD) && unlink ($TFNAME);

                                # Remove old files
    system "rm -f moonphase*.{gif,png} $OFNAME";

                                # Consistency check
    die "Error: Couldn't remove old file ($OFNAME)\n"
        if (-e $OFNAME) || (-l $OFNAME);

                                # Max. frame number (starting at zero)
    my $MaxFrameNum = $NUMFRAMES - ONE;

#---------------------------------------------------------------------
# Main loop.

    for my $ii (ZERO..$MaxFrameNum)
    {                           # Generate the next frame
        my $nn = sprintf ('%03d', $ii);
        my $xx = sprintf ('%.3f', $ii/$NUMFRAMES);

        my $pngfile = "moonphase$nn.png";
        my $giffile = "moonphase$nn.gif";

        system << "END";        # "END" must be double-quoted here
perl moonphasepic.pl $xx --output=$pngfile --width=$WIDTH
END
        if (!$is_avi)           # Is the target an  animated GIF ?
        {                       # Yes - Convert PNG frame to GIF frame
            system "convert $pngfile $giffile";
            unlink $pngfile;    # Discard PNG frame
        }
    }

#---------------------------------------------------------------------
# If GIF mode is selected, make an animated GIF.

# The  "gifsicle" command executed below creates a temporary (unoptim-
# ized)  animated-GIF  file  using 256 colors.  The "intergif" command
# executed afterwards  creates the final (optimized) animated-GIF file
# using $IGNUMCOLORS colors.

# Note: The extra spaces used in the $cmd block defined below are sig-
# nificant.  Don't  add  spaces or  remove them  unless you know  what
# you're doing.

    if (!$is_avi)               # Is the target an animated GIF ?
    {                           # Yes
        my $IGDELAY;
        $IGDELAY = int ((($FPS / $NUMFRAMES) * 100) + 0.5);
        $IGDELAY = 2 if $IGDELAY < 2;

        $cmd = << "END";        # "END" must be double-quoted here
gifsicle -i -O -l --colors 256
    moonphase[0-9][0-9][0-9].gif -o $TFNAME
intergif -i -t -trim -d $IGDELAY -loop -diffuse -zigzag
    -best $IGNUMCOLORS $TFNAME -o $OFNAME
rm -f $TFNAME moonphase[0-9][0-9][0-9].gif
END
        $cmd =~ s@\s*\n[\011\040]+@ @gs;
        $cmd =~ s@\s+\z@@s;
        system $cmd;
    }

#---------------------------------------------------------------------
# If AVI mode is selected, make an AVI file.

# Note: The extra spaces used in the $cmd block defined below are sig-
# nificant.  Don't  add  spaces or  remove them  unless you know  what
# you're doing.

    if ($is_avi)                # Is the target an AVI file?
    {                           # Yes
        $cmd = << "END";        # "END" must be double-quoted here
mencoder "mf://moonphase*.png"
    -mf w=$WIDTH:h=$HEIGHT:fps=$FPS:type=png
    -ovc lavc -lavcopts vcodec=mpeg4 -oac copy -o $OFNAME
rm -f moonphase*.png
END
        $cmd =~ s@\s*\n[\011\040]+@ @gs;
        $cmd =~ s@\s+\z@@s;
        system $cmd;
    }

#---------------------------------------------------------------------
# Wrap it up.

    die "Error: Operation failed\n" unless -f $OFNAME;
    print "Created $OFNAME\n";
    undef;
}

#---------------------------------------------------------------------
#                            main program
#---------------------------------------------------------------------

&Main();                        # Call the main routine
exit ZERO;                      # Normal exit
