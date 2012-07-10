#!/usr/bin/env perl
# moonphasepic - Generates a Moon picture with phase shadow added
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
- Generates a Moon picture with phase shadow

Recommended: Remove the ".pl"  filename extension and set file permis-
sions to 755 octal.

Usage:  __META_NAME__ now   --output=foo.png
        __META_NAME__ 0.52  --output=foo.png

        --info=foo.txt    Create an informational text file
        --width=360       Change image width

This program creates a PNG image file. "--output" specifies the image-
file name (or pathname).  If "--output" isn't used, the image is saved
to "moonphase.png" in the user's home directory.

If "now" is specified, the phase is based on the current date.  A num-
ber between  zero and  one (inclusive) may be  specified instead.  The
number specifies a point  in the lunar cycle  (for example: zero = New
Moon, 0.25 = 1st quarter, 0.50 = Full Moon, and 0.75 = 3rd quarter).

"--info=foo.txt" writes a short description of the image to the speci-
fied text file.  If "--info" isn't used, no text file is  created.  To
change the image width, use "--width" as shown above.
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

use constant FALSE => 0;        # Boolean FALSE
use constant TRUE  => 1;        # Boolean TRUE

                                # Approx. value of "pi"
my $PI = 3.14159265358979323846264338327950288419716939937510;

my $DEGREES_PER_HALF   = 180;   # Number of degrees per half-circle
my $DEGREES_PER_CIRCLE = 360;   # Number of degrees per circle
                                # Number of radians per degree
my $RADIANS_PER_DEGREE = (2 * $PI) / $DEGREES_PER_CIRCLE;

#---------------------------------------------------------------------
#                         additional modules
#---------------------------------------------------------------------

use Cwd;                        # Provided with Perl
use Math::Trig;                 # Ditto

my $HaveCPAN = FALSE;           # Flag:  Have CPAN module
                                # Try to load CPAN module
eval 'use Astro::MoonPhase; $HaveCPAN = TRUE;';
                                # See if module was loaded
die "Error: The CPAN module Astro::MoonPhase is needed\n"
    unless $HaveCPAN;

#---------------------------------------------------------------------
#                         program parameters
#---------------------------------------------------------------------

my $PROGNAME  = 'moonphasepic'; # Program name (should be one word)
my $REVISION  = '120709';       # Revision string
                                # Name of base-image file
my $IMAGE_MAP = "albedo_simp750.jpg";

my $LIGHT_DISTANCE  = 5000;     # Should be from 100 to 5000
my $LIGHT_INTENSITY = 1.70;     # Should be from 1.0 to 2.0

#---------------------------------------------------------------------

# $DEFAULT_WIDTH and $DEFAULT_HEIGHT  specify the default output width
# and height, respectively (in pixels).  The factory settings are  400
# and 300. Note: The associated aspect ratio should be 4/3.

my $DEFAULT_WIDTH  = 400;
my $DEFAULT_HEIGHT = 300;

#---------------------------------------------------------------------

#  The "$POVTMP..." files are used  primarily to  work around restric-
# tions imposed by POV-Ray. Specifically, POV-Ray complains when path-
# names are used for files. It doesn't seem to like  symbolic links to
# absolute paths  either.  As a  work-around,  we move files around so
# that POV-Ray doesn't need to see paths.

# Note: This problem is a POV-Ray configuration issue.  Theoretically,
# users could fix the problem by modifying their POV-Ray configuration
# files, but we'd prefer to avoid this.

#  $POVTMPDIR          = Absolute pathname for temporary directory
my $POVTMPDIR          = "/var/tmp";

#  $POVTMPNAME_IMGFILE = Name of image output file without path
#  $POVTMPNAME_MAPFILE = Name of image map    file without path
#  $POVTMPNAME_SRCCODE = Name of POV-Ray code file without path

my $POVTMPNAME_IMGFILE = "moonphase-out-$>-$$.png";
my $POVTMPNAME_MAPFILE = "moonphase-map-$>-$$.jpg";
my $POVTMPNAME_SRCCODE = "moonphase-src-$>-$$.pov";

#  $POVTMPPATH_IMGFILE = Name of image output file with path
#  $POVTMPPATH_MAPFILE = Name of image map    file with path
#  $POVTMPPATH_SRCCODE = Name of POV-Ray code file with path

my $POVTMPPATH_IMGFILE = "$POVTMPDIR/$POVTMPNAME_IMGFILE";
my $POVTMPPATH_MAPFILE = "$POVTMPDIR/$POVTMPNAME_MAPFILE";
my $POVTMPPATH_SRCCODE = "$POVTMPDIR/$POVTMPNAME_SRCCODE";

#---------------------------------------------------------------------
#                        POV-Ray code template
#---------------------------------------------------------------------

# The following  block of code is written in  POV-Ray's scene descrip-
# tion language.

my $POV_CODE = << 'END_OF_POV_CODE';
#include "colors.inc"
#include "functions.inc"

light_source {
    <__META_X__, 0, __META_Z__>
    color <__META_LIGHT_COLOR__>
}

camera {
    location <0, 0, -2.5>
    look_at  <0, 0, 0>
}

#local pg_fn = function {
    pigment {
        image_map {
            jpeg "__META_IMAGE_MAP__"
            map_type 1
            interpolate 2
        }
    }
}

isosurface {
    function {
        f_sphere (x, y, z, 1)
    }
    max_gradient 1.810
    texture {
        pigment {
            function { pg_fn (x, y, z).gray }
        }

        finish {
            ambient rgb <0, 0, 0.24>
            diffuse 1.0
            specular 0.1
            roughness 0.05
        }
    }

    rotate -90 * y
}
END_OF_POV_CODE

#---------------------------------------------------------------------
#                           misc. routines
#---------------------------------------------------------------------

# "UsageError" prints the program's "usage" text and exits.

sub UsageError
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
#                            main routine
#---------------------------------------------------------------------

sub Main
{
    my $angle;                  # An angle (expressed in radians)
    my $str;                    # Scratch
    my $time;                   # UNIX time value

    my $info;                   # Information related to image
    my $ofname;                 # Image -file name (or pathname)
    my $txtfile;                # Info  -file name (or pathname)

    my $frac;                   # Point  in  lunar cycle  (ranges from
                                # zero to one, inclusive)

    my $x;                      # X-coordinate of light source
    my $z;                      # Z-coordinate of light source
                                # Output width and height (in pixels)
    my $OutWidth  = $DEFAULT_WIDTH;
    my $OutHeight = $DEFAULT_HEIGHT;

#---------------------------------------------------------------------
# Initial setup.

                                # Note: STDERR must be set first here
    select STDERR; $| = ONE;    # Force STDERR flush on write
    select STDOUT; $| = ONE;    # Force STDOUT flush on write

#---------------------------------------------------------------------
# Process the command line.

    for my $arg (@ARGV)         # Process all  arguments
    {                           # Process next argument
        if ($arg =~ m@^now\z@i)
        {
            &UsageError() if defined $frac;
            $time = time;
            $frac = phase ($time);
            $info = 'time ' . $time;
        }
        elsif (($arg =~ m@^\d+\.?\d*\z@) && ($arg <= 1.0))
        {
            &UsageError() if defined $frac;
            $frac =  $arg;
            $frac =~ s@\.\z@@;
            $info =  'frac ' . $frac;
        }
        elsif ($arg =~ m@^-+info=(\S+)\z@)
        {
            $txtfile =  $1;
            $txtfile =~ s@^["']+@@;
            $txtfile =~ s@["']+\z@@;
        }
        elsif ($arg =~ m@^-+out(|put)=(\S+)\z@)
        {
            $ofname =  $2;
            $ofname =~ s@^["']+@@;
            $ofname =~ s@["']+\z@@;
        }
        elsif (($arg =~ m@^-+width=(\d+)\z@) &&
            ($1 >= 48) && ($1 <= 2048))
        {
            $OutWidth  = $1;
            $OutHeight = int (((3 * $OutWidth) / 4) + 0.5);
        }
        else
        {
            &UsageError();
        }
    }

    &UsageError() unless defined $frac;

#---------------------------------------------------------------------
# Check external programs.

    my @progs = qw (povray);    # Build list of programs needed

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
# Set default output-file name.

    if (!defined ($ofname) || !length ($ofname))
    {
        $str    = $ENV {HOME};
        $str    = '/tmp' unless defined ($str) && length ($str);
        $ofname = "$str/moonphase.png";
    }

#---------------------------------------------------------------------
# Safety measure.

    for my $ref_path (\$ofname, \$txtfile)
    {
        my $xfname = $$ref_path;
        next unless defined $xfname;

        unlink $xfname;         # Remove symbolic link (if necessary)
                                # Try to create the file
        open (OFD, ">$xfname") ||
            die "Error: Can't create file: $!\n$xfname\n";

        print OFD "Test\n";
        close (OFD) ||
            die "Error: Can't write to file: $!\n$xfname\n";

                                # Try to remove the file
        if (!unlink ($xfname) || -e $xfname || -l $xfname)
        {
            die "Error: Can't remove file: $!\n$xfname\n";
        }
    }

#---------------------------------------------------------------------
# Handle required computations.

                                # Point in  lunar cycle,  expressed as
                                # an angle (in degrees)
    my $deg360 = $frac * $DEGREES_PER_CIRCLE;

                                # Safety measure
    $deg360 = $DEGREES_PER_CIRCLE if $deg360 > $DEGREES_PER_CIRCLE;

    my $xs  = ONE;              # Sign of X-coordinate (-1 or +1)
    my $zs  = ONE;              # Sign of Z-coordinate (-1 or +1)

                                # Determine related parameters
    if (($frac >= 0.00) && ($frac < 0.25))
    {                           # 1st quarter
        $angle =  $deg360 * $RADIANS_PER_DEGREE;
        $info  .= "\n1st quarter and waxing\n";
    }
    elsif (($frac >= 0.25) && ($frac <= 0.50))
    {                           # 2nd quarter
        $angle =  ($DEGREES_PER_HALF - $deg360)
                 * $RADIANS_PER_DEGREE;
        $info  .= "\n2nd quarter and waxing\n";
        $zs    =  -1;
    }
    elsif (($frac > 0.50) && ($frac < 0.75))
    {                           # 3rd quarter
        $angle =  ($deg360 - $DEGREES_PER_HALF)
                           * $RADIANS_PER_DEGREE;
        $info  .= "\n3rd quarter and waning\n";
        $xs    =  -1;
        $zs    =  -1;
    }
    else
    {                           # 4th quarter
        $angle =  ($DEGREES_PER_CIRCLE - $deg360)
                 * $RADIANS_PER_DEGREE;
        $info  .= "\n4th quarter and waning\n";
        $xs    =  -1;
    }
                                # Compute X and Z coordinates
    $x = $xs * $LIGHT_DISTANCE * abs (sin ($angle));
    $z = $zs * $LIGHT_DISTANCE * abs (cos ($angle));

#---------------------------------------------------------------------
# Generate a POV-Ray source file.

    my $L = $LIGHT_INTENSITY;

    $str =  $POV_CODE;
    $str =~ s@__META_IMAGE_MAP__@$POVTMPNAME_MAPFILE@g;
    $str =~ s@__META_LIGHT_COLOR__@$L, $L, $L@g;
    $str =~ s@__META_X__@$x@g;
    $str =~ s@__META_Z__@$z@g;

    my $TF = 'temporary file';
    open (OFD, ">$POVTMPPATH_SRCCODE") ||
        die "Error: Can't create $TF: $!\n$POVTMPPATH_SRCCODE\n";
    print OFD $str;
    close (OFD) ||
        die "Error: Can't write to $TF: $!\n$POVTMPPATH_SRCCODE\n";

#---------------------------------------------------------------------
# Run POV-Ray.

# Note: POV-Ray makes some  kludges related to  temporary files neces-
# sary.  For more information,  see the comments preceding the defini-
# tions of $POVTMPDIR near the start of this file.

    my $CWD = getcwd();         # Current working directory
                                # Try to create temporary directory
                                # If  this fails,  it'll  be caught by
                                # the "chdir" command below
    system "/bin/mkdir -p $POVTMPDIR";

                                # Make temporary copy of base image
    system "/bin/cp $IMAGE_MAP $POVTMPPATH_MAPFILE";

                                # Go to temporary directory
    chdir ($POVTMPDIR) ||
        die "Error: Can't go to directory: $!\n$POVTMPDIR\n";

                                # Build appropriate "povray" command
    $str = << "END";
povray +I$POVTMPNAME_SRCCODE +O$POVTMPNAME_IMGFILE
+W$OutWidth +H$OutHeight -D
END
    $str =~ s@\s+@ @gs;
    $str =~ s@\s+\z@@s;
    system $str;                # Execute the "povray" command

    unlink $POVTMPPATH_MAPFILE; # Delete temporary files
    unlink $POVTMPPATH_SRCCODE;
                                # Return to original directory
    chdir ($CWD) ||
        die "Error: Can't go to directory: $!\n$CWD\n";

                                # Move output image to final location
    system "/bin/mv $POVTMPPATH_IMGFILE $ofname";

#---------------------------------------------------------------------
# Generate image-info file (if requested).

    if (defined ($txtfile) && open (OFD, ">$txtfile"))
    {
        if ($info =~ m@^frac (\d+\.?\d*)\n(\S.+?)\s*\z@s)
        {
            my ($p1, $p2) = ($1, $2);
            $p1 *= 100;

            $info = << "END";
This is the Moon ${p1}\% of the way through its cycle. Zero is equal
to New Moon and 50\% is equal to Full Moon. At this point, the Moon
is in its $p2
END
        }
        elsif ($info =~ m@^time (\d+)\n(\S.+?)\s*\z@s)
        {
            my ($p1, $p2) = ($1, $2);
            $str = localtime ($p1);
            $str =~ s@ \d\d:\d\d:\d\d ([A-Z]\w* +|)@ @;
            $str =~ s@\s+@ @g;
            $str =~ s@\s+\z@@s;

            $info = << "END";
This is the Moon as of $str. At this point, the Moon is
in its $p2
END
        }
        else
        {
            $info = 'moonphasepic: Internal error';
        }

        $info =~ s@\s+\z@@s;
        $info =~ s@\.*\z@.@;

        if (($frac >= 0.85) || ($frac <= 0.15))
        {
            $info .= "\n\n";
            $info .= << "END";
Note: The Moon is invisible because it's close to the start of the
lunar cycle.
END
        }

        $info =~ s@\s*\z@\n@;
        print OFD $info;
        close OFD;
    }

#---------------------------------------------------------------------
# Wrap it up.

    if (-f $ofname)
    {
        print "Created $ofname";
        print " and $txtfile" if defined $txtfile;
        print "\n";
    }
    else
    {
        die "Error: Operation failed for unknown reasons\n";
    }

    undef;
}

#---------------------------------------------------------------------
#                            main program
#---------------------------------------------------------------------

&Main();                        # Call the main routine
exit ZERO;                      # Normal exit
