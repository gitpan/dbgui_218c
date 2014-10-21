#!/net/pvcsserv01/sft/gnu/bin/perl
#!/usr/local/bin/perl
################################################################################
##                                                                            ##
## Author     :  Monty Scroggins                                              ##
## Description:  Perform database commands with a GUI interface               ##
##                                                                            ##
##  Parameters:  none                                                         ##
##                                                                            ##
## +++++++++++++++++++++++++++ Maintenance Log ++++++++++++++++++++++++++++++ ##
## Tue Sep 1 02:30:59 GMT 1998  Monty Scroggins - Script created.
##    verified to work on RedHat Linux 5.1 and Solaris 2.6
##
## Mon Oct 9 16:00:54 GMT 1998   Added code to perform db commands other than
##    select statements.  Changed listbox to text widget to accomodate
##
## Sun Nov 1 18:39:51 GMT 1998  Many Enhancements - Snapshots, Print, Datatypes,
##    Enable/Disable Command Strings, remove/replace table header on queries,
##    Save file requester.   Many bug fixes
##
## Fri Nov 13 00:15:38 GMT 1998 More bug fixes
##
## Mon Jan 25 22:49:59 GMT 1999 Changed filerequester to new getFileName()
##    Also added Optionset calls to set default colors - trimmed 10% :-)
##
## Mon Feb 1 23:21:16 GMT 1999  Added commandtype assoc array to force row/column style
##    for certain "sp_" commands
##
## Sun Feb 21 11:48:14 CST 1999 Added Menubutton "Method" to force any command to be
##    executed with the system isql command even though the output is really ugly  ;-)
##
## Wed Mar 31 19:00:52 CST 1999 Re-wrote handling of multiple result sets.  Now multiple
##    result sets are detected and the header/sort functions are disabled.  Also
##    added Sqsh executable option for comparison
##
## Tue Apr 20 12:02:51 CDT 1999 Various cleaning up....  fixed a bug where the scroll
##    positions were not being restored after a DB command.
##
## Thu Apr 28 19:30:29 CDT 1999 Added clone window....  added functionality to allow
##    saving of the cloned data to a file. Added a datestring to the titlebars to indicate
##    the date/time of the sampled data
##
## Fri May 14 15:15:47 CDT 1999 Fixed problem with search dialog losing the histories
##
## Tue May 18 13:55:06 CDT 1999 Fixed problem where I wasnt displaying the errors returned
##     if an invalid command (for example) was executed on the server..  (no result sets returned)
##
## Tue May 25 17:47:55 CDT 1999  Moved the row/column counters to the top.  Makes for a smaller
##     and more efficient display.
##
## Wed Jun 9 12:11:05 CDT 1999  Added the small change to display pound symbols instead of the
##     actual text for the password entry.  Changed the busy indicator to a simple colored frame
##     for simplicity.
##
## Wed Jun 16 17:54:50 CDT 1999  Made some minor - mostly cosmetic changes.  Fixed a bug where
##     the sql command was being printed twice in a save file.
##
## Tue Jun 22 17:14:03 CDT 1999  Added the file as an argument to allow pre-defined
##     menu histories to be defined and kept in separate database files.
##
## Fri Jul 9 14:05:10 CDT 1999 Version 2.0.  Ported to DBI/DBD!. Fixed a bug in the handling of
##     sql strings which include special characters.  Some small cosmetic changes.  Moved the
##     row/column counters towards the bottom (again)...   Localized many variables.  Enabled
##     multiple clone windows to be displayed.  Changed the widths of the columns to be data
##     related.  No more need for special column handling, the display is always as compact as
##     possible.  Changed to sprintf's in an attempt to speed up the column padding
##
## Tue Oct 19 18:56:25 CDT 1999  Added the capability to sum up the sorted column
##
## Tue Oct 26 11:37:46 CDT 1999 Fixed a bug where the tmp file wasnt being specified for printing
##     the sql results!!.  How did I miss that one!
##
## Tue Jan 11 18:53:21 CST 2000  Added code to generate the print dialog instead of relying on
##     the printdialog module.   
##
## Wed Jan 19 17:37:33 CST 2000  Fixed a bug where the sort function was causing the column
##     count to be incremented by the original column count instead of counting from zero!?
##
## Tue Mar 21 11:02:29 CST 2000  Minor tweak to keep the sort option in a specific state until
##     the user changes it
##
## Thu Mar 30 12:06:48 CST 2000  Added the SQL edit feature to make it easier to change
##     really long SQL commands .
##
## Tue Oct 3 17:38:53 CDT 2000   Added a test to see if the PrintDialog window is displayed
##     before configuring some of the subwidgets.. Perl 5.6/Tk8022 combination required this. 
##
################################################################################

#the current version
my $VERSION="2.1.8c";

=head1 NAME

DBGUI - a database server graphical interface.

=head1 DESCRIPTION

DBGUI features:

=over 4

Perform any SQL command.

Save the SQL results to a file.

Perform incremental or standard searches or the SQL results.

Keep a history of _all_ SQL commands and parameters.

Sort (normal, numerical and reverse) on any column of the SQL results.

Print the SQL results to a printer.

Quick command line clear and restore for easy command line generation/pasting.

"Clone" the results to a new display window for comparisons etc.

Utilize the DBI/DB libraries or isql/sqsh binaries for the queries.

Maintain four complete configuration "snapshots" for easy retrieval.

Reload the last set of parameters on startup.

Interactively enable and disable any or all of three different command lines for execution.  All of
the 'active' command lines are concatenated, therefore the three command entry lines can be used to
quickly eliminate/add command parameters to an existing command.

Display the column data type in each column header.

Display the column data width in each column header.

Solicit and quickly popup a list of the system datatypes.

Colored busy indicator (red/green) to indicate if the DBGUI is waiting on results from the DB server.

The date/time of command execution is captured in the title bar.

The checkpoint file can be specified as an argument. Allowing pre-defined menu histories to be defined

More probably....  :^)

=back

=head1 PREREQUISITES

This script requires the following Perl Modules:

=over 4

C<Tk Toolkit>

C<DBI>

C<DBD>

C<Sort::Fields>

C<Tk::HistEntry>

C<Tk::PrintDialog>

=back


=pod SCRIPT CATEGORIES

CPAN/Administrative
Fun/Educational

=cut

use Tk;
#entry widget with history menu
use Tk::HistEntry;
#DBI/DBD package
use DBI;
#debug
#DBI->trace(2);
use Sys::Hostname;

#sort library
use Sort::Fields;

#wrap used in reporting DB error text 
use Text::Wrap;

#the ROText widget is used in the print dialog 
use Tk::ROText;

#perl variables
$|=1;      # set output buffering to off
$[ = 0;    # set array base to 0
$, = ' ';  # set output field separator
$\ = "\n"; # set output record separator
$" = "\n"; # set the list element separator

#The colors and such
my $txtbackground="snow2";
my $txtforeground="black";
my $background="bisque3";
my $troughbackground="bisque4";
my $buttonbackground="tan";
my $headerbackground='#f0f0c7';
my $headerforeground='#800000';
my $datatypeforeground='#604030';
my $winfont="8x13bold";
my $labelbackground='bisque2';
my $rowcolcolor='#002030';
my $entrywidth=11;
my $toplabelwidth=12;
my $tophistentrywidth=9;
my $buttonwidth=4;
my $ypad=4;
my $busycolor="red2",
my $unbusycolor='#00af00',
my $histlimit=100;
my $delim='#@';
#get the hostname used for the connection info in the server
my $localhostname=hostname;
#######################################################################
#DBD module specific settings.
# in an attempt to make this program as portable as possible, I am setting
# some variables to be used to define specific parameters that have to be
# used for a given DBD module.   Hopefully these will apply to most of the
# DBD modules and you can simply change these values.
#
#the servertype is used to tell DBI which interface module to load.
my $servertype="Sybase";

#the DBD client error handler to startup
my $errorhandler="syb_err_handler";

#the DBD client data types definition
my $dbtypes="syb_types";

#the result types function
my $resulttypes="syb_result_type";

#ctlib defined datatypes as defined in cstypes.h
my %dbdatatypes=qw(
   -1     illeg
    0     char
    1     bin
    2     lchar
    3     lbin
    4     text
    5     image
    6     tnyint
    7     smint
    8     int
    9     real
   10     float
   11     bit
   12     date
   13     date4
   14     money
   15     money4
   16     numer
   17     dec
   18     varch
   19     varbin
   20     long
   21     sens
   22     bndry
   23     void
   24     ushort
);

#######################################################################


#if these binaries are on the path, set to just "isql" or "sqsh"
#I set these to the complete paths because many of my users do not
#have the nfs filesystem which contains these binaries on their
#search paths..

#the path to the isql binary
my $isqlbinary="/net/pvcsserv01/sft/sybase/bin/isql";
#the path to the sqsh binary
my $sqshbinary="/net/pvcsserv01/sft/tools/sqsh";

#the sql command used to extract the defined datatypes from the database
my $dbtypescmd="select type,length,name from systypes";

#available printers
my @printers=("hp4si-678-1158","Print to File");

#set to the postscript printing program.  We use a2ps
my $psprint="/net/pvcsserv01/sft/gnu/opt/a2ps/bin/a2ps";

#the tempfile used for printing
my $printfile="/tmp/dbgui.ps";

#the default print font size
my $size_set=10;

#the default number of copies to print
my $copies=1;

#a list of variables that are saved in the checkpoint file
my @variablelist=qw(
srchstring
method
timeout
dbserver
dbuser
dbpass
dbuse
maxrowcount
querystring1
querystring2
querystring3
qsactive1
qsactive2
qsactive3
snapshot0
snapshot1
snapshot2
snapshot3
snapshot4
);

#a list of arrays that are saved in the checkpoint file
my @arraylist=qw(
dbservhist
dbuserhist
dbpasshist
dbusehist
queryhist1
queryhist2
queryhist3
searchhist
);

#check the arguments.  If one is given it has to be checkpoint file to load.  If none
#is given, use the home directory
my $checkf="$ARGV[0]";
my $checkpointfile="$ENV{HOME}/.dbgui";

#if the checkpoint file is not found and a real value has been passed as ARGV0 (will be created)
if (!-f $checkf && $checkf) {
   $checkpointfile=$checkf;
   }

#if the checkpoint file is found in the home directory, use it
if (-f "$ENV{HOME}\/$checkf") {
   $checkpointfile="$ENV{HOME}/$checkf";
   }

#if the checkpoint file contains a full path, use it
if (-f "$checkf") {
   $checkpointfile="$checkf";
   }

#if it just doesnt exist, prompt to create it
if (!-f $checkpointfile) {
   $confirmwin->destroy if Exists($confirmwin);
   $confirmwin = Tk::MainWindow->new;
   $confirmwin->withdraw;
   $confirmbox=$confirmwin->messageBox(
      -type=>'OKCancel',
      -bg=>$background,
      -font=>'8x13bold',
      -title=>"Prompt",
      -text=>"The Checkpoint file \"$checkpointfile\" does not exist...\nCreate it??",
      );
   if ($confirmbox eq "Ok") {
      #set the defaults for the sliders etc.. mostly so the scale widgets will startup properly
      $snapshot=0;
      $timeout=30;
      $method="DBI/DBD";
      $maxrowcount=1000;
      &checkpoint;
      }else{
         exit;
         }
   }#if ! -f checkf

#if the checkpoint file exists, execute it to startup in the same state as when it was shutdown
if (-e $checkpointfile) {
  require ("$checkpointfile");
  }

#startup with the last data in the widgets
$snapshot=0;

#make sure the alarmstring is empty
$alarmstring="";

#the initial setting for the app is to perform sorts
$sortoverride=0;

#a list of potentially dangerous commands that should be operator confirmed before being executed
my @dangercmds=qw(
update
delete
truncate
drop
shutdown
kill
);

#reset the data counters
$dbrowcount=0;
$dbcolcount=0;

#set the initial maxrowcount to 1000 if not defined  a nice number
if (!$maxrowcount) {
   $maxrowcount=1000;
   };

#set the initial method
if (!$method) {
   $method="DBI/DBD";
   };

#set the initial timeout for queries
if (!$timeout) {
   $timeout=30;
   };

#the alarm will trigger a cancel for the currently executing command
$SIG{ALRM}=\&alarm_handler;

#$SIG{ALRM} = sub { $sth && $sth->cancel; };
#                                       Main Window
#------------------------------------------------------------------------------------------
#
my $LW = new  MainWindow (-title=>"DBGUI $VERSION  [$checkpointfile]");
#set some inherited default colors
$LW->optionAdd("*background","$background");
$LW->optionAdd("*foreground","$txtforeground");
$LW->optionAdd("*highlightBackground", "$background");
$LW->optionAdd("*Button.Background", "$buttonbackground");
$LW->optionAdd("*activeForeground", "$txtforeground");
$LW->optionAdd("*Menubutton*Background", "$buttonbackground");
$LW->optionAdd("*Menubutton*activeForeground", "$txtforeground");
$LW->optionAdd("*Label*Background", "$labelbackground");
$LW->optionAdd("*troughColor", "$troughbackground");
$LW->optionAdd("*borderWidth", "1");
$LW->optionAdd("*highlightThickness", "0");
$LW->optionAdd("*font", "$winfont");
$LW->optionAdd("*label*relief", "flat");
$LW->optionAdd("*frame*relief", "flat");
$LW->optionAdd("*button*relief", "raised");
$LW->optionAdd("*Checkbutton*relief", "raised");
$LW->optionAdd("*optionmenu*relief", "raised");

#set an initial size
$LW->minsize(85,2);
$LW->geometry("85x3");

#label frame
$listframeall=$LW->Frame(
   -borderwidth=>'1',
   -relief=>'sunken',
   )->pack(
      -fill=>'both',
      -expand=>1,
      -pady=>0,
      -padx=>0,
      -side=>'top',
      );

$buttonframe=$LW->Frame(
   )->pack(
      -fill=>'x',
      -pady=>0,
      -padx=>0,
      -side=>'bottom',
      );

$rowcolframe=$LW->Frame(
   )->pack(
      -fill=>'x',
      -pady=>0,
      -padx=>0,
      -side=>'bottom',
      );

##################### Begin frames for top row of elements  ####################

my $labelframe=$listframeall->Frame(
   -borderwidth=>'0',
   )->pack(
      -fill=>'x',
      -expand=>0,
      -pady=>0,
      -padx=>0,
      -side=>'top',
      );

my $labelent1=$labelframe->Frame(
   -relief=>'raised',
   -background=>$labelbackground,
   )->pack(
      -fill=>'y',
      -expand=>0,
      -pady=>0,
      -padx=>0,
      -side=>'left',
      );

my $labelent2=$labelframe->Frame(
   -relief=>'raised',
   -background=>$labelbackground,
   )->pack(
      -fill=>'y',
      -expand=>0,
      -pady=>0,
      -padx=>0,
      -side=>'left',
      );

my $labelent3=$labelframe->Frame(
   -relief=>'raised',
   -background=>$labelbackground,
   )->pack(
      -fill=>'y',
      -expand=>0,
      -pady=>0,
      -padx=>0,
      -side=>'left',
      );

my $labelent4=$labelframe->Frame(
   -relief=>'raised',
   -background=>$labelbackground,
   )->pack(
      -fill=>'y',
      -expand=>0,
      -pady=>0,
      -padx=>0,
      -side=>'left',
      );

my $labelent5=$labelframe->Frame(
   -relief=>'raised',
   -background=>$labelbackground,
   )->pack(
      -fill=>'y',
      -expand=>0,
      -pady=>0,
      -padx=>0,
      -side=>'left',
      );

my $labelent6=$labelframe->Frame(
   -relief=>'raised',
   -background=>$labelbackground,
   )->pack(
      -fill=>'y',
      -expand=>0,
      -pady=>0,
      -padx=>0,
      -side=>'left',
      );

my $labelent7=$labelframe->Frame(
   -relief=>'raised',
   -background=>$labelbackground,
   )->pack(
      -fill=>'y',
      -expand=>0,
      -pady=>0,
      -padx=>0,
      -side=>'left',
      );

my $labelent8=$labelframe->Frame(
   -relief=>'raised',
   -background=>$labelbackground,
   )->pack(
      -fill=>'y',
      -expand=>0,
      -pady=>0,
      -padx=>0,
      -side=>'left',
      );

$busymarker=$labelframe->Frame(
   -relief=>'raised',
   -width=>34,
   -height=>15,
   -background=>$unbusycolor,
   )->pack(
      -expand=>0,
      -pady=>0,
      -padx=>1,
      -side=>'right',
      );

##################### end top row of elements  ####################

my $listframe1=$listframeall->Frame(
   -borderwidth=>'0',
   -relief=>'sunken',
   )->pack(
      -fill=>'both',
      -expand=>1,
      -pady=>0,
      -padx=>0,
      );

##############################################
#  query string parameters
$labelent1->Label(
   -text=>'DB Server',
   -width=>$toplabelwidth,
   )->pack(
      -fill=>'x',
      -side=>'top',
      -padx=>0,
      -pady=>0,
      -expand=>0,
      );

my $servhistframe=$labelent1->Frame(
   -relief=>'sunken',
   )->pack(
      -side=>'bottom',
      -expand=>0,
      -pady=>0,
      -padx=>1,
      );

$dbserventry=$servhistframe->HistEntry(
   -relief=>'flat',
   -textvariable=>\$dbserver,
   -selectforeground=>$txtforeground,
   -selectbackground=>'#c0d0c0',
   -background=> 'white',
   -width=>$tophistentrywidth,
   -limit=>$histlimit,
   -dup=>0,
   -match=>0,
   -command=>sub{@dbservhist=$dbserventry->history;},
   -justify=>'center',
   )->pack(
      -side=>'left',
      -expand=>0,
      -pady=>0,
      -padx=>0,
      -fill=>'x',
      );

$dbserventry->bind('<Return>'=>\&check_cmd);
$dbserventry->history([@dbservhist]);

$labelent2->Label(
   -text=>'Username',
   -width=>$toplabelwidth,
   )->pack(
      -fill=>'y',
      -padx=>0,
      -pady=>0,
      -expand=>0,
      -side=>'top',
      );

my $userhistframe=$labelent2->Frame(
   -relief=>'sunken',
   )->pack(
      -side=>'bottom',
      -expand=>0,
      -pady=>0,
      -padx=>1,
      );

$dbuserentry=$userhistframe->HistEntry(
   -relief=>'flat',
   -textvariable=>\$dbuser,
   -highlightcolor=>'black',
   -selectforeground=>$txtforeground,
   -selectbackground=>'#c0d0c0',
   -borderwidth=>0,
   -background=> 'white',
   -width=>$tophistentrywidth,
   -limit=>$histlimit,
   -dup=>0,
   -match=>0,
   -justify=>'center',
   -command=>sub{@dbuserhist=$dbuserentry->history;},
   )->pack(
      -expand=>0,
      -padx=>0,
      -pady=>0,
      -fill=>'x',
      );

$dbuserentry->bind('<Return>'=> \&check_cmd);
$dbuserentry->history([@dbuserhist]);

$labelent3->Label(
   -text=>'Password',
   -width=>$toplabelwidth,
   )->pack(
      -fill=>'y',
      -side=>'top',
      -padx=>0,
      -pady=>0,
      -expand=>0,
      );

my $passhistframe=$labelent3->Frame(
   -relief=>'sunken',
   )->pack(
      -side=>'bottom',
      -expand=>0,
      -pady=>0,
      -padx=>1,
      );


$dbpassentry=$passhistframe->HistEntry(
   -relief=>'flat',
   -textvariable=>\$dbpass,
   -highlightcolor=>'black',
   -selectforeground=>$txtforeground,
   -selectbackground=>'#c0d0c0',
   -borderwidth=>0,
   -background=> 'white',
   -width=>$tophistentrywidth,
   -limit=>$histlimit,
   -dup=>0,
   -match=>0,
   -justify=>'center',
   -show => '#',
   -command=>sub{@dbpasshist=$dbpassentry->history;},
   )->pack(
      -expand=>0,
      -padx=>0,
      -pady=>0,
      -fill=>'x',
      );

$dbpassentry->bind('<Return>'=>\&check_cmd);
$dbpassentry->history([@dbpasshist]);


$labelent4->Label(
   -text=>'Use DB',
   -width=>$toplabelwidth,
   )->pack(
      -fill=>'y',
      -side=>'top',
      -padx=>0,
      -pady=>0,
      -expand=>0,
      );

my $dbusehistframe=$labelent4->Frame(
   -relief=>'sunken',
   )->pack(
      -side=>'bottom',
      -expand=>0,
      -pady=>0,
      -padx=>1,
      );

$dbuseentry=$dbusehistframe->HistEntry(
   -relief=>'flat',
   -textvariable=>\$dbuse,
   -highlightcolor=>'black',
   -selectforeground=>$txtforeground,
   -selectbackground=>'#c0d0c0',
   -borderwidth=>0,
   -background=> 'white',
   -width=>$tophistentrywidth,
   -limit=>$histlimit,
   -justify=>'center',
   -dup=>0,
   -match=>0,
   -command=>sub{@dbusehist=$dbuseentry->history;},
   )->pack(
      -expand=>0,
      -padx=>0,
      -pady=>0,
      -fill=>'x',
      );

$dbuseentry->bind('<Return>'=>\&check_cmd);
$dbuseentry->history([@dbusehist]);

$labelent5->Label(
   -text=>'Max Rows',
   -width=>$toplabelwidth,
   )->pack(
      -fill=>'y',
      -side=>'top',
      -padx=>0,
      -pady=>0,
      );

my $maxrowentry=$labelent5->Entry(
   -textvariable=>\$maxrowcount,
   -width=>$toplabelwidth,
   -background=>'white',
   -selectforeground=>$txtforeground,
   -selectbackground=>'#c0d0c0',
   -relief=>'sunken',
   -justify=>'center',
   )->pack(
      -side=>'bottom',
      -expand=>1,
      -padx=>1,
      -pady=>0,
      -fill=>'y',
      );

$maxrowentry->bind('<Return>'=>\&check_cmd);
#use button three to toggle between two often used values and a third number (hidden feature)
$maxrowentry->bind('<Button-3>'=>sub{
   my $tmaxcount=$maxrowcount;
   if ($tmaxcount !=0 && $tmaxcount !=20) {
      $savmaxcount=$maxrowcount;
      $maxrowcount=0;
      }
   if ($tmaxcount==0) {
      $maxrowcount=20;
      }
   if ($tmaxcount==20) {
      if (!$savmaxcount) {
         $savmaxcount=0;
         }
      $maxrowcount=$savmaxcount;
      }
   });

$labelent6->Label(
   -text=>'Snapshot',
   -width=>$toplabelwidth,
   )->pack(
      -fill=>'y',
      -side=>'top',
      -padx=>0,
      -pady=>0,
      );

$labelent6->Label(
   -textvariable=>\$snapshot,
   -width=>1,
   -background=>$txtbackground,
   -relief=>'sunken',
   )->pack(
      -side=>'right',
      -expand=>1,
      -padx=>1,
      -pady=>1,
      -fill=>'y',
      );

my $snapscale=$labelent6->Scale(
   -variable=>\$snapshot,
   -orient=>'horizontal',
   -label=>'',
   -from=>0,
   -to=>4,
   -length=>86,
   -troughcolor=>$txtbackground,
   -sliderlength=>14,
   -width=>19,
   -showvalue=>0,
   -command=>sub{&run_snapshot("$snapshot");},
   )->pack(
      -side=>'bottom',
      -padx=>0,
      -pady=>0,
      -fill=>'y',
      );
$snapscale->bind('<Return>'=> \&check_cmd);

$labelent7->Label(
   -text=>'Method',
   -width=>$toplabelwidth,
   )->pack(
      -fill=>'y',
      -side=>'top',
      -padx=>0,
      -expand=>0,
      );

my $methodframe=$labelent7->Frame(
   -relief=>'sunken',
   -height=>20,
   -borderwidth=>1,
   )->pack(
      -side=>'bottom',
      -expand=>1,
      -pady=>0,
      -padx=>0,
      -fill=>'x',
      );

my $methodmenu=$methodframe->Menubutton(
   -textvariable=>\$method,
   -relief=>'sunken',
   -indicatoron=>1,
   -borderwidth=>0,
   -background=>$txtbackground,
   )->pack(
      -side=>'bottom',
      -padx=>0,
      -pady=>0,
      -fill=>'x',
      );

$methodmenu->command(
   -label=>'DBI/DBD Libraries',
   -command=>sub{$method="DBI/DBD";},
   -background=>$background,
   );

$methodmenu->command(
   -label=>'Isql Binary',
   -command=>sub{$method="Isql";},
   -background=>$background,
   );

$methodmenu->command(
   -label=>'Sqsh Binary',
   -command=>sub{$method="Sqsh";},
   -background=>$background,
   );

$labelent8->Label(
   -text=>'Timeout',
   -width=>$toplabelwidth,
   )->pack(
      -fill=>'y',
      -side=>'top',
      -padx=>0,
      -expand=>0,
      );

$labelent8->Label(
   -textvariable=>\$timeout,
   -width=>3,
   -background=>$txtbackground,
   -relief=>'sunken',
   )->pack(
      -side=>'right',
      -expand=>1,
      -padx=>1,
      -pady=>1,
      -fill=>'y',
      );

# the highth is controlled with the width  option.  The slider width is the sliderlength
my $timescale=$labelent8->Scale(
   -variable=>\$timeout,
   -orient=>'horizontal',
   -label=>'',
   -from=>0,
   -to=>600,
   -length=>70,
   -troughcolor=>$txtbackground,
   -sliderlength=>14,
   -width=>19,
   -showvalue=>0,
   -resolution=>30,
   -borderwidth=>1,
   )->pack(
      -side=>'bottom',
      -padx=>0,
      -pady=>0,
      -fill=>'y',
      );
$timescale->bind('<Return>'=> \&check_cmd);

##############################################
#query strings

my $qs1frame=$listframe1->Frame(
   -relief=>'sunken',
   -highlightthickness=>0,
   )->pack(
      -expand=>0,
      -pady=>0,
      -padx=>0,
      -fill=>'x',
      );

my $clr1=$qs1frame->Button(
   -text=>"CTR",
   -width=>2,
   -command=>sub{
      if ($querystring1 ne "") {
         $qs1sav=$querystring1;
         $querystring1="";
         };},
   )->pack(
      -side=>'left',
      -expand=>0,
      -padx=>0,
      -fill=>'y',
      );

#use button two to chop off the last word of the query string
$clr1->bind('<Button-2>'=>sub{
   $qs1sav=$querystring1;
   $querystring1=~s/\ *$//;
   my $trimword1=(split(/ /,$querystring1))[-1];
   if ($trimword1 ne "") {
      $querystring1=~s/\Q$trimword1\E$//;
      }
   });

#use button three to restore the clear operation
$clr1->bind('<Button-3>'=>sub{
   if ($qs1sav) {
      $querystring1=$qs1sav;
      }
   });

$qscheck1=$qs1frame->Checkbutton(
   -variable=>\$qsactive1,
   -background=>$buttonbackground,
   -text=>">",
   -borderwidth=>1,
   -selectcolor=>'red4',
   -width=>2,
   -offvalue=>0,
   -onvalue=>1,
   -command=>sub{&act_deactivate("qsentry1","qsactive1")},
   )->pack(
      -side=>'left',
      -expand=>0,
      -padx=>0,
      -fill=>'y',
      );

$qsedit1=$qs1frame->Button(
   -relief=>'raised',
   -text=>"E",
   -width=>1,
   -command=>sub{&cmdedit('1')},
   )->pack(
      -side=>'right',
      -expand=>0,
      -padx=>0,
      );

$qsentry1=$qs1frame->HistEntry(
   -relief=>'flat',
   -textvariable=>\$querystring1,
   -highlightcolor=>'black',
   -selectforeground=>$txtforeground,
   -selectbackground=>'#c0d0c0',
   -borderwidth=>0,
   -background=> 'white',
   -limit=>$histlimit,
   -dup=>1,
   -match=>0,
   -command=>sub{@queryhist1=$qsentry1->history;},
   )->pack(
      -fill=>'both',
      -expand=>1,
      -pady=>1,
      );

$qsentry1->bind('<Return>'=>\&check_cmd);
$qsentry1->history([@queryhist1]);

my $qs2frame=$listframe1->Frame(
   -relief=>'sunken',
   )->pack(
      -expand=>0,
      -pady=>0,
      -padx=>0,
      -fill=>'x',
      );

my $clr2=$qs2frame->Button(
   -text=>"CTR",
   -width=>2,
   -command=>sub{
      if ($querystring2 ne "") {
         $qs2sav=$querystring2;
         $querystring2="";
         };},
   )->pack(
      -side=>'left',
      -expand=>0,
      -padx=>0,
      -fill=>'y',
      );

#use button two to chop off the last word
$clr2->bind('<Button-2>'=>sub{
   $qs2sav=$querystring2;
   $querystring2=~s/\ *$//;
   my $trimword2=(split(/ /,$querystring2))[-1];
   if ($trimword2 ne "") {
      $querystring2=~s/\Q$trimword2\E$//;
      }
   });

#use button three to restore the clear operation
$clr2->bind('<Button-3>'=>sub{
   if ($qs2sav) {
      $querystring2=$qs2sav;
      }
   });

$qscheck2=$qs2frame->Checkbutton(
   -variable=>\$qsactive2,
   -relief=>'raised',
   -text=>">",
   -background=>$buttonbackground,
   -selectcolor=>'red4',
   -width=>2,
   -offvalue=>0,
   -onvalue=>1,
   -command=>sub{&act_deactivate("qsentry2","qsactive2")},
   )->pack(
      -side=>'left',
      -expand=>0,
      -padx=>0,
      -fill=>'y',
      );

$qsedit2=$qs2frame->Button(
   -relief=>'raised',
   -text=>"E",
   -width=>1,
   -command=>sub{&cmdedit('2')},
   )->pack(
      -side=>'right',
      -expand=>0,
      -padx=>0,
      -fill=>'y',
      );

$qsentry2=$qs2frame->HistEntry(
   -relief=>'flat',
   -textvariable=>\$querystring2,
   -highlightcolor=>'black',
   -selectforeground=>$txtforeground,
   -selectbackground=>'#c0d0c0',
   -borderwidth=>0,
   -background=> 'white',
   -limit=>$histlimit,
   -dup=>1,
   -match=>0,
   -command=>sub{@queryhist2=$qsentry2->history;},
   )->pack(
      -fill=>'both',
      -expand=>1,
      -pady=>1,
      );

$qsentry2->bind('<Return>'=>\&check_cmd);
$qsentry2->history([@queryhist2]);

my $qs3frame=$listframe1->Frame(
   -relief=>'sunken',
   )->pack(
      -expand=>0,
      -pady=>0,
      -padx=>0,
      -fill=>'x',
      );

my $clr3=$qs3frame->Button(
   -text=>"CTR",
   -width=>2,
   -command=>sub{
      if ($querystring3 ne "") {
         $qs3sav=$querystring3;
         $querystring3="";
         };},
   )->pack(
      -side=>'left',
      -expand=>0,
      -padx=>0,
      -fill=>'y',
      );

#use button two to chop off the last word
$clr3->bind('<Button-2>'=>sub{
   $qs3sav=$querystring3;
   $querystring3=~s/\ *$//;
   my $trimword3=(split(/ /,$querystring3))[-1];
   if ($trimword3 ne "") {
      $querystring3=~s/\Q$trimword3\E$//;
      }
   });

#use button three to restore the clear operation
$clr3->bind('<Button-3>'=>sub{
   if ($qs3sav) {
      $querystring3=$qs3sav;
      }
   });

$qscheck3=$qs3frame->Checkbutton(
   -variable=>\$qsactive3,
   -relief=>'raised',
   -text=>">",
   -background=>$buttonbackground,
   -selectcolor=>'red4',
   -width=>2,
   -offvalue=>0,
   -onvalue=>1,
   -command=>sub{&act_deactivate("qsentry3","qsactive3")},
   )->pack(
      -side=>'left',
      -expand=>0,
      -padx=>0,
      -fill=>'y',
      );
      
$qsedit3=$qs3frame->Button(
   -relief=>'raised',
   -text=>"E",
   -width=>1,
   -command=>sub{&cmdedit('3')},
   )->pack(
      -side=>'right',
      -expand=>0,
      -padx=>0,
      -fill=>'y',
      );

$qsentry3=$qs3frame->HistEntry(
   -relief=>'flat',
   -textvariable=>\$querystring3,
   -highlightcolor=>'black',
   -selectforeground=>$txtforeground,
   -selectbackground=>'#c0d0c0',
   -borderwidth=>0,
   -background=> 'white',
   -limit=>$histlimit,
   -dup=>1,
   -match=>0,
   -command=>sub{@queryhist3=$qsentry3->history;},
   )->pack(
      -fill=>'both',
      -expand=>1,
      -pady=>1,
      );

$qsentry3->bind('<Return>'=>\&check_cmd);
$qsentry3->history([@queryhist3]);

#padding for spacing between the query strings and the output Text widget
   $listframe1->Frame(
   -relief=>'sunken',
   -height=>3,
   )->pack(
      -side=>'top',
      -padx=>0,
      -pady=>0,
      -expand=>0,
      -fill=>'x',
      );

#-----------------------------------------------------------------------------
#                                   data listboxes

$scrolly=$listframe1->Scrollbar(
   -orient=>'vert',
   -elementborderwidth=>1,
   -width=>12,
   )->pack(
      -side=>'right',
      -fill=>'y',
      );

$scrollx=$listframe1->Scrollbar(
   -orient=>'horiz',
   -elementborderwidth=>1,
   -width=>14,
   )->pack(
      -side=>'bottom',
      -fill=>'x',
      );

$queryheader=$listframe1->Text(
   -xscrollcommand=>['set', $scrollx],
   -relief=>'raised',
   -background=>$headerbackground,
   -foreground=>$headerforeground,
   -selectforeground=>$txtforeground,
   -selectbackground=>'#c0d0c0',
   -setgrid=>'yes',
   -wrap=>'none',
   -height=>2,
   -exportselection=>1,
   )->pack(
      -fill=>'x',
      -expand=>0,
      -pady=>0,
      -anchor=>'n',
      );

$queryout=$listframe1->Text(
   -yscrollcommand=>['set', $scrolly],
   -xscrollcommand=>['set', $scrollx],
   -relief=>'raised',
   -borderwidth=>1,
   -background=>$txtbackground,
   -selectforeground=>$txtforeground,
   -selectbackground=>'#c0d0c0',
   -wrap=>'none',
   -height=>14,
   -exportselection=>1,
   )->pack(
      -fill=>'both',
      -expand=>1,
      -pady=>0,
      );

$scrolly->configure(-command=>['yview', $queryout]);
$scrollx->configure(-command=>\&my_xscroll);

my $menu=$queryout->Menu( -menuitems => $menuitems );
my $textmenu=$queryout->GetMenu;

#------------------------------------------------------------------------------------------
#                              bottom row of buttons and labels

my $rownumlabel=$rowcolframe->Label(
   -text=>' Rows:',
   -foreground=>$rowcolcolor,
   -background=>$background,
   -justify=>'right'
   )->pack(
      -side=>'left',
      -padx=>0,
      -pady=>0,
      );

$rowcolframe->Label(
   -textvariable=>\$dbrowcount,
   -width=>8,
   -background=>$txtbackground,
   -foreground=>$rowcolcolor,
   -relief=>'sunken',
   )->pack(
      -side=>'left',
      -padx=>0,
      -pady=>0,
      -fill=>'y',
      );

my $colnumlabel=$rowcolframe->Label(
   -text=>' Cols:',
   -foreground=>$rowcolcolor,
   -background=>$background,
   -justify=>'right'
   )->pack(
      -side=>'left',
      -padx=>0,
      -pady=>0,
      );

$rowcolframe->Label(
   -textvariable=>\$dbcolcount,
   -width=>8,
   -background=>$txtbackground,
   -foreground=>$rowcolcolor,
   -relief=>'sunken',
   )->pack(
      -side=>'left',
      -padx=>0,
      -pady=>0,
      -fill=>'y',
      );

$rowcolframe->Label(
   -textvariable=>\$alarmstring,
   -foreground=>$rowcolcolor,
   -background=>$background,
   -relief=>'flat',
   )->pack(
      -side=>'top',
      -fill=>'x',
      -padx=>0,
      -pady=>0,
      );


my $sortframe=$buttonframe->Frame(
   -relief=>'sunken',
   )->pack(
      -side=>'left',
      -padx=>0,
      -pady=>0,
      -expand=>1,
      -fill=>'x',
      );

#bindings for this label are below the sortbyentry declaration
my $sumbutton=$sortframe->Button(
   -text=>'Sum',
   -relief=>'raised',
   -background=>$buttonbackground,
   -width=>3,
   -command=>\&total_col
   )->pack(
      -side=>'left',
      -padx=>0,
      -pady=>$ypad,
      -fill=>'y',
      );
      
#bindings for this label are below the sortbyentry declaration
my $sortbutton=$sortframe->Button(
   -text=>'Sort',
   -relief=>'raised',
   -width=>3,
   -background=>$buttonbackground,
   -command=>sub {
      ($tscrolly,$rest)=$queryout->yview;
      ($tscrollx,$rest)=$queryout->xview;
      &sortby($tscrollx,$tscrolly);
      },
   )->pack(
      -side=>'left',
      -padx=>0,
      -pady=>$ypad,
      );

#the sortby textvariable will be configured after the window is created.
my $sortbyentry=$sortframe->Optionmenu(
   -background=>$buttonbackground,
   -width=>24,
   )->pack(
      -side=>'left',
      -expand=>1,
      -pady=>$ypad,
      -padx=>0,
      -fill=>'both',
      );

#use button three disable sorting for the next command only. (hidden feature)
#the sort settings are restored after the initial execution
$sortbutton->bind('<Button-1>'=>sub{
   $sortoverride=0;
   $sortbutton->configure(-foreground=>$txtforeground);
#   $sortbyentry->configure(-state=>'normal');
   });
$sortbutton->bind('<Button-3>'=>sub{
   $sortoverride=1;
   $sortbutton->configure(-foreground=>'grey65');
   });

my $revsortbutton=$sortframe->Checkbutton(
   -variable=>\$reversesort,
   -text=>"Rev",
   -background=>$buttonbackground,
   -borderwidth=>1,
   -selectcolor=>'red4',
   -width=>4,
   -offvalue=>0,
   -onvalue=>1,
   )->pack(
      -side=>'left',
      -expand=>0,
      -padx=>0,
      -pady=>$ypad,
      -fill=>'y',
      );

my $numsortbutton=$sortframe->Checkbutton(
   -variable=>\$numsort,
   -text=>"Num",
   -background=>$buttonbackground,
   -borderwidth=>1,
   -selectcolor=>'red4',
   -width=>4,
   -offvalue=>0,
   -onvalue=>1,
   )->pack(
      -side=>'left',
      -expand=>0,
      -padx=>0,
      -pady=>$ypad,
      -fill=>'y',
      );

#frame for spacing
$sortframe->Frame(
   -borderwidth=>'0',
   -width=>2,
   )->pack(
      -side=>'right',
      -padx=>0,
      -pady=>0,
      -expand=>0,
      );

#frame for spacing
$buttonframe->Frame(
   -borderwidth=>'0',
   -width=>2,
   )->pack(
      -side=>'left',
      -padx=>0,
      -pady=>0,
      -expand=>0,
      );

$buttonframe->Button(
   -text=>'Exit',
   -width=>$buttonwidth,
   -command=>sub{&checkpoint;exit},
   )->pack(
      -side=>'right',
      -padx=>0,
      -pady=>2,
      );

$buttonframe->Button(
   -text=>'Search',
   -width=>$buttonwidth,
   -command=>\&searchit,
   )->pack(
      -side=>'right',
      -padx=>1,
      -pady=>2,
      );

my $printbutton=$buttonframe->Button(
   -text=>'Print',
   -width=>$buttonwidth,
   -command=>\&printdialog,
   )->pack(
      -side=>'right',
      -padx=>0,
      -pady=>2,
      );

my $savebutton=$buttonframe->Button(
   -text=>'Save',
   -width=>$buttonwidth,
   -command=>sub{&savit("");},
   )->pack(
      -side=>'right',
      -padx=>1,
      -pady=>2,
      );

my $typesbutton=$buttonframe->Button(
   -text=>'Clone',
   -width=>$buttonwidth,
   -command=>\&clone_data,
   )->pack(
      -side=>'right',
      -padx=>0,
      -pady=>2,
      );

#frame for which to stick the menubutton.  Menubuttons dont line up right with a
#row of buttons so I have to put them into a frame and pad with another empty frame  :-\
my $mbframe=$buttonframe->Frame(
   )->pack(
      -side=>'right',
      -padx=>0,
      -pady=>2,
      -expand=>0,
      -fill=>'y',
      );

my $mbutton=$mbframe->Menubutton(
   -text=>' Snap',
   -width=>$buttonwidth-1,
   -relief=>'raised',
   -indicatoron=>1,
   )->pack(
      -side=>'right',
      -padx=>0,
      -pady=>2,
      -fill=>'y',
      );

$mbutton->command(
   -label=>'Take Snapshot 1',
   -command=>sub{&take_snapshot("1");},
   );
$mbutton->command(
   -label=>'Take Snapshot 2',
   -command=>sub{&take_snapshot("2");},
   );
$mbutton->command(
   -label=>'Take Snapshot 3',
   -command=>sub{&take_snapshot("3");},
   );
$mbutton->command(
   -label=>'Take Snapshot 4',
   -command=>sub{&take_snapshot("4");},
   );

my $querybutton=$buttonframe->Button(
   -text=>'Exec',
   -width=>$buttonwidth,
   -foreground=>'red4',
   -command=>\&check_cmd,
   )->pack(
      -side=>'right',
      -padx=>0,
      -pady=>2,
      );

#this is important to do initially otherwise the histories wont be checkpointed
$dbserventry->invoke;
$dbuserentry->invoke;
$dbpassentry->invoke;

$qsentry1->invoke;
$qsentry2->invoke;
$qsentry3->invoke;

$qscheck1->update;
$qscheck2->update;
$qscheck3->update;

&act_deactivate("qsentry1","qsactive1");
&act_deactivate("qsentry2","qsactive2");
&act_deactivate("qsentry3","qsactive3");

#record the pack info for header and the data listboxes..
#needed when switching between command mode and query mode
@headerinfo=$queryheader->packInfo;
@datainfo=$queryout->packInfo;

#ensure default is on the list of dbusehist
my $founddefault=grep(/^default/,@dbusehist);
if ($founddefault lt "1") {
   push (@dbusehist,"default");
   $dbuseentry->history([@dbusehist]);
   }
$dbuseentry->invoke;

my $tscrollx=0.0;
my $tscrolly=0.0;

#force the optionmenu to be invoked, otherwise the first query will be sorted twice
$sortby="     ";
$sortbyentry->configure(-textvariable=>\$sortby);

MainLoop();

#                                         subroutines
#
#------------------------------------------------------------------------------------------

sub cmdedit {
   ($item)=@_;
   return if ($item eq "");
   #The main qsedit window
   $EW->destroy if Exists($EW);
   $EW=new MainWindow(-title=>"SQL Edit");
   $EW->optionAdd("*borderWidth", "1");
   $EW->optionAdd("*highlightThickness", "0");
   $EW->optionAdd("*troughColor", "$troughbackground");
   $EW->optionAdd("*background","$background");
   #set a minimum size so the window cant be resized down to mess up the buttons
   $EW->minsize(484,144);
   #The top frame for the text
   my $qseditframe1=$EW->Frame(
      -borderwidth=>'0',
      -relief=>'flat',
      )->pack(
         -expand=>1,
         -fill=>'both',
         );

   #frame for the buttons
   my $qseditframe2=$EW->Frame(
      -borderwidth=>'0',
      -relief=>'flat',
      )->pack(
         -fill=>'x',
         -expand=>0,
         );
         
   $qseditwin=$qseditframe1->Scrolled('Text',
      -font=>$winfont,
      -scrollbars=>'e',
      -wrap=>'word',
      -width=>92,
      -height=>7,
      -relief=>'sunken',
      -background=>$txtbackground,
      -foreground=>$txtforeground,
      )->pack(
          -expand=>1,
          -fill=>'both',
          );
          
   $qseditframe2->Button(
      -text=>'Cancel',
      -width=>5,
      -background=>$buttonbackground,
      -foreground=>$txtforeground,
      -font=>$winfont,
      -command=>sub{$EW->destroy;}
      )->pack(
         -expand=>0,
         -side=>'right',
         -padx=>0,
         -pady=>2,
         );

   $qseditframe2->Button(
      -text=>'Accept',
      -width=>5,
      -background=>$buttonbackground,
      -foreground=>$txtforeground,
      -font=>$winfont,
      -command=>sub{&apply_edit;},
      )->pack(
         -expand=>0,
         -side=>'right',
         -padx=>1,
         -pady=>2,
         );
      $itemstring="querystring$item";
      $qseditwin->insert('end',"$$itemstring");
}#sub cmdedit

sub apply_edit {
   my $editstring=$qseditwin->get('0.0','end');
   $editstring=~s/\n//g;
   $$itemstring=$editstring;
   $EW->destroy if Exists($EW);
}#sub apply edit

sub clone_data {
   my $clonedate=$LW->cget(-title);
   #collect the x scroll setting so it can be set to the same as the real data window
   ($clscrollx,$rest)=$queryout->xview;
   ($clscrolly,$rest)=$queryout->yview;
   #The main clone window
   $CW->destroy if Exists($CW);
   $CW=new MainWindow(-title=>"Cloned Data - $clonedate");
   #set a minimum size so the window cant be resized down to mess up the cancel button
   $CW->minsize(884,244);
   #The top frame for the text
   my $cloneframe1=$CW->Frame(
      -borderwidth=>'0',
      -relief=>'flat',
      -background=>$background,
      )->pack(
         -expand=>1,
         -fill=>'both',
         );

   #frame for the buttons
   my $cloneframe2=$CW->Frame(
      -borderwidth=>'0',
      -relief=>'flat',
      -background=>$background,
      -height=>60,
      )->pack(
         -fill=>'x',
         -expand=>0,
         );

   # Create a scrollbar on the right side and bottom of the text
   my $hscrolly=$cloneframe1->Scrollbar(
      -orient=>'vert',
      -elementborderwidth=>1,
      -highlightthickness=>0,
      -background=>$background,
      -troughcolor=>$troughbackground,
      -relief=>'flat',
      )->pack(
         -side=>'right',
         -fill =>'y',
         );

   my $hscrollx=$cloneframe1->Scrollbar(
      -orient=>'horiz',
      -elementborderwidth=>1,
      -highlightthickness=>0,
      -background=>$background,
      -troughcolor=>$troughbackground,
      -relief=>'flat',
      )->pack(
         -side=>'bottom',
         -fill=>'x',
         );

   $cloneheader=$cloneframe1->Text(
      -font=>$winfont,
      -xscrollcommand=>['set', $hscrollx],
      -relief=>'flat',
      -highlightthickness=>0,
      -background=>$headerbackground,
      -foreground=>$headerforeground,
      -selectforeground=>$txtforeground,
      -selectbackground=>'#c0d0c0',
      -wrap=>'none',
      -height=>2,
      -width=>102,
      )->pack(
         -fill=>'x',
         -expand=>0,
         -pady=>0,
         -anchor=>'n',
         );

   $clonewin=$cloneframe1->Text(
      -yscrollcommand => ['set', $hscrolly],
      -xscrollcommand => ['set', $hscrollx],
      -font=>$winfont,
      -relief => 'sunken',
      -highlightthickness=>0,
      -foreground=>$txtforeground,
      -background=>$txtbackground,
      -borderwidth=>1,
      -wrap=>'none',
      -height=>10,
      -width=>102,
      -exportselection=>1,
      )->pack(
         -expand=>1,
         -fill=>'both',
         );

   $hscrolly->configure(-command => ['yview',$clonewin]);
   $hscrollx->configure(-command=>\&my_clonexscroll);

   $cloneframe2->Label(
      -textvariable=>\$clonestat,
      -borderwidth=>1,
      -background=>'#eeeedd',
      -foreground=>$txtforeground,
      -font=>$winfont,
      -relief=>'sunken'
      )->pack(
         -side=>'left',
         -expand=>1,
         -padx=>3,
         -pady=>3,
         -fill=>'both',
         );

   $cloneframe2->Button(
      -text=>'Cancel',
      -borderwidth=>1,
      -width=>5,
      -background=>$buttonbackground,
      -foreground=>$txtforeground,
      -highlightthickness=>0,
      -font=>$winfont,
      -command=>sub{$CW->destroy;}
      )->pack(
         -expand=>0,
         -side=>'right',
         -padx=>0,
         -pady=>2,
         );

   $clonesavebutton=$cloneframe2->Button(
      -text=>'Save',
      -borderwidth=>1,
      -width=>5,
      -background=>$buttonbackground,
      -foreground=>$txtforeground,
      -highlightthickness=>0,
      -font=>$winfont,
      -command=>sub{&clone_savit("");},
      )->pack(
         -expand=>0,
         -side=>'right',
         -padx=>1,
         -pady=>2,
         );

  $cldbcmd=$cloneframe2->Menubutton(
      -text=>'Cmd',
      -relief=>'raised',
      -indicatoron=>0,
      -borderwidth=>1,
      -background=>$buttonbackground,
      -highlightthickness=>0,
      -width=>7,
      -tearoff=>0,
      -font=>$winfont,
      )->pack(
         -side=>'right',
         -padx=>0,
         -pady=>2,
         -fill=>'y',
         );

   #if there has been more than one resultcount returned, dont display the header
   if ($resultcount==1) {
      my @tdata=$queryheader->get('0.0','end');
      chomp $tdata[0];
      $cloneheader->insert('end',$tdata[0]);
      $cloneheader->insert('end',$tdata[1]);
      }else{
         $cloneheader->packForget;
         };
   my @tdata=$queryout->get('0.0','end');
   $clonewin->insert('end',@tdata);
   #generate the status string for the clone window
   if ($method =~/DBI\/DBD|Sybase/ && $resultcount==1) {
      $clonestat="S:$dbserver  R:$dbrowcount  C:$dbcolcount  DB:$dbuse  MR:$maxrowcount  Meth:$method  Sort:$sortby ";
      }else{
         $clonestat="Server:$dbserver  Database:$dbuse  MaxRows:$maxrowcount  Meth:$method";         
         }
   $savsqlstring=~s/^ +//;
   $savsqlstring=~s///;
   $cldbcmd->command(
      -label=>"$savsqlstring",
      -background=>$txtbackground,
      -activeforeground=>$txtforeground,
      -activebackground=>$txtbackground,
      );
      #scroll the window to display the same lines as the original window
      $cloneheader->xview(moveto=>$clscrollx);
      $clonewin->xview(moveto=>$clscrollx);
      $clonewin->yview(moveto=>$clscrolly);
}#sub clone

#tie two text widgets (header and data) to scroll horizontally together
sub my_xscroll {
   $queryheader->xview(@_);
   $queryout->xview(@_);
   }#sub

#tie two text widgets (header and data) to scroll horizontally together
sub my_clonexscroll {
   $cloneheader->xview(@_);
   $clonewin->xview(@_);
   }#sub

sub operconfirm {
   if ($dangerflag==1) {
      $ask=$LW->messageBox(
         -icon=>'warning',
         -type=>'OKCancel',
         -default=>'Cancel',
         -bg=>$background,
         -title=>'Action Confirm',
         -text=>"You are about to perform a potentially dangerous command on\n\n$dbserver!\n\nPlease confirm the action before\nit is executed..",
         -font=>'8x13bold',
         );
      return $ask;
      }else{
         return "Ok";
         }
}#sub operconfirm

#connect with the server and execute the proper command
sub check_cmd {
   $alarmstring="";
   $dbrowcount="";
   $dbcolcount="";
   #collect the x scroll setting so it can be resumed after the sort
   ($tscrollx,$rest)=$queryout->xview;
   ($tscrolly,$rest)=$queryout->yview;
   #remove any spaces that can accidentally be put into the query parameters.
   #spaces can fail a query if they are left in
   foreach ("dbserver","dbuser","dbpass","dbuse","maxrowcount") {
      ${$_}=~s/ //g;
      }
   $dbserventry->invoke;
   $dbuserentry->invoke;
   $dbpassentry->invoke;
   $dbuseentry->invoke;
   $qsentry1->invoke;
   $qsentry2->invoke;
   $qsentry3->invoke;
   $dangerflag=0;	
   #start the command clean
   $sqlstring="";
   @dbretrows=();
   $confirm="";
   #set the newsearch flag to ensure any searching of the dbdata is restarted from the start since
   #new data will be generated..
   $newsearch=1;
   #force the query button to a normal state before the display is locked
   $querybutton->configure(-state =>'normal');
   $LW->update;
   #build the sql command string... to be used by the server and the isql binary too
   foreach ("querystring1","querystring2","querystring3") {
      #check to see which of the sql strings is enabled with the checkbutton -
      #only collect and concatenate the enabled sql string lines
      $qsmark=substr($_,-1);
      $qsmark="qsactive$qsmark";
      if (${$qsmark}==1) {
         ${$_}=~s/^ *//;
         $sqlstring.="${$_} ";
         #get the first word of the sql string to check against the dangercmds list
         $verb=(split(/ +\w/,${$_}))[0];
         #check to see if the command is one of the dangerous ones to enable the confirmation when executed
         if (grep(/^$verb$/i,@dangercmds)) {
            $dangerflag=1;
            }
         }#if qsmark eq 1
      }#foreach query string
   return if ($sqlstring=~/^ *$/);
   &setbusy;
   $confirm=&operconfirm;
   if ($confirm eq "Ok") {
      $date=localtime(time());
      $LW->configure(-title=>"DBGUI $VERSION  [$checkpointfile]  $date");
      #save off a wrapped version of the sqlstring for the ascii save files
      $savsqlstring=wrap("    ","    ","$sqlstring");
      #the header has to be nulled out for querys and db commands
      $queryheader->delete('0.0','end');
      $queryout->delete('0.0','end');
      $LW->update;
      #cant decide if the checkpoint file needs to be saved every time a command is executed..
      #&checkpoint;
      #if the menuitem on the display is set to Isql or sqsh, call the isql binary for the
      #dbcommand and skip all of the other stuff
      &checkpoint;
      if ($method eq "Isql"||$method eq "Sqsh") {
         $" = ""; #set the list element separator
         &run_isql_cmd;
         &setunbusy;
         return;
         }
      $" = "\n"; #set the list element separator
      &run_query;
      }else{
         &setunbusy;
         }
      #if confirm eq OK
}#sub check_cmd

#sub to actually execute a DB query. the run_command routine execs all other DB commands
#with the messagehandler, there is no need to check each command for successful status
sub run_query {
   #these MUST be localized
   my ($dbh,$status);
   #connect to the database and run the command
   $dbh=DBI->connect("dbi:$servertype:server=$dbserver;hostname=$localhostname",$dbuser,$dbpass);
   #if the login info is bad, complain and quit.  The error handler posts the errors returned
   #from the libraries.  No need to add to them inmanually (except for the initial $dbh connection
   if (!$dbh) {
      $queryheader->packForget;
      $queryout->insert('end',"\n ERROR:\n\n A connection to database server was unable to be established..\n");
      $queryout->insert('end',"\n Please check the username, password and servername etc..\n\n");
      &setunbusy;
      return(1);
      }#if !dbh
   $dbh->{$errorhandler}=\&err_handler;
   if (int($maxrowcount)>0) {
      $status=$dbh->do("set rowcount $maxrowcount");
      if ($status==0) {
         $queryheader->packForget;
         return;
         }#if status eq 0
      }#if ($maxrowcount=~/\d+/) {
   #if the dbuse variable is not set to default, specifically set it.
   if ($dbuse !~ /^default$/i) {
      $status=$dbh->do("use $dbuse");
      if ($status==0) {
         $queryheader->packForget;
         return;
         }#if status eq 0
      }#if dbuse is not default
   $resultcount=0;
   @sortbyhist=();
   $sth=$dbh->prepare($sqlstring);
   $sth->execute;
   # schedule alarm in $timeout seconds
   alarm($timeout);
   #if an error occured, the error handler will post the error text to the user, All that needs to
   #be done here is to return.
   if ($sth->err) {
      alarm();
      return 1;
      }

   #loop to execute for * each * result set returned
   do {
      @sortbyhisttemp=@sortbyhist;
      my @tempdbretrows="";
      $spstat=$sth->{$resulttypes};
      #if no status is returned , dont attempt to parse the results..
      #This happens when a db command is executed that returns
      #no data - like truncate etc..  Set to an unbusy state and return
      if (!$spstat) {
         &setunbusy;
         alarm();
         return(0);
         }
      #get the column names
      my $colnames=$sth->{NAME};
      #get the column widths
      my $colsizes=$sth->{PRECISION};
      #get the column datatypes
      my $coltypes=$sth->{$dbtypes};

      ################################## Build the header ###################################
      #get the number of columns
      my $headerstring="";
      my $colheaderstring=();
      my $collengthheaderstring=();
      my $divider="";
      #for each resultset, get the headerinfo and set the width to whichever one is longest
      for($i=0;$i<=$#$colnames;++$i) {
         #get the name of each column
         $colheader=@$colnames[$i];
         $colheader=~s///;
         if ($colheader!~/^ $/) {
            #push the column name onto the sortby
            push(@sortbyhist,$colheader);
            }
         #get the english description of the column datatypes returned from sybase
         my $dispcoltype=$dbdatatypes{@$coltypes[$i]};
         my $sybcollength=@$colsizes[$i];
         my $dispcollength="$dispcoltype $sybcollength";
         #collect the length of the column header string
         $hlength{$i}=length($colheader);

         #check to see if the column length string is longer, if so use it for the column
         my $clength=length($dispcollength);
         if ($clength > $hlength{$i}) {
            $hlength{$i}=$clength;
            }

         $headerstring.="$colheader$delim";
         $collengthheaderstring.="$dispcollength$delim";
         $divider.="!!rsdim$delim";
         }#for($i=0;$i<=$#$colnames;++$i) {

      #push both lines of the header and the divider onto the temp data array
      push(@tempdbretrows,"$headerstring");
      push(@tempdbretrows,"$collengthheaderstring");
      push(@tempdbretrows,"$divider");
      ################################## pull in the data ###################################
      #for each row returned from the query..
      # for each row of data returned
      while($dbdata=$sth->fetch) {
         #Pull together the data returned for sorting and display
         my $dbrowstring="";
         #dont use foreach here to ensure the data is in proper order
         # for each item of each row    #
         for($x=0; $x<scalar(@$dbdata); ++$x) {
            #calculate the length of the real returned data
            my $element="@$dbdata[$x]";
            $element=~s// /;
            #To ensure consistent parsing, if the column is a null, set it to be a single space
            if ($element=~/^$/) {
               $element="\ ";
               }
            #$element=~s///; #trim trailing spaces
            my $elementlength=length($element);
            if ($elementlength > $hlength{$x}) {
               $hlength{$x}=$elementlength;
               }
            #tack on a delimiter for sorting
            $dbrowstring.="$element$delim";
            }#foreach @dbdata
         push(@tempdbretrows,"$dbrowstring");
      }#while ($d=$sth->fetch)
      #now all data has been collected for the resultset, pad the data to fit the calculated column
      #widths and push the final data onto the real data array
      for($z=0; $z<scalar(@tempdbretrows); ++$z) {
         my $finalout="";
         my @elements=split("$delim","$tempdbretrows[$z]");
         for($i=0; $i<scalar(@elements); ++$i) {
            my $operstring=$elements[$i];
            #if the element is flagged to be a resultset delimiter, create a divider line instead
            #of padding with spaces
            if ($operstring eq "!!rsdim") {
               $operstring="";
               for($y=0; $y<$hlength{$i}; ++$y) {
                  $operstring.="-";
                  }
               }#if ($operstring eq "!!rsdim")
            #pad the operstring with spaces
            $operstring=sprintf("%-$hlength{$i}\s",$operstring);
            $finalout="$finalout$operstring | ";
            }#for($i=0; $i<scalar(@elements); ++$i)
         push (@dbretrows, "$finalout");
         }#for($z=0; $z<scalar(@tempdbretrows;
      #push out an empty line for a divider between result sets
      push (@dbretrows, " ");
      $resultcount++;
      }while($sth->{syb_more_results});
   # cancel the alarm
   alarm();
   $dbh->disconnect;
   #4043 is the status from the server for the sql command.  It is returned as a separate result
   #set.  If it is detected, chop the data out of the final data and remove the column from the
   #sort history
   if ($spstat==4043) {
      splice(@dbretrows,-5,5);
      @sortbyhist=@sortbyhisttemp;
      $resultcount--;
      }

   #if only one resultset has been returned, populate and display the pretty header
   #otherwise display the plain db text
   if ($resultcount==1 && $skipsort==0) {
      #take off the first few elements of the retrows array until real data is encountered
      #or until there is no data on the array at all (like when a truncate command etc is executed)
      until ($dbretrows[0]=~/^\w+/||!$dbretrows[0]) {
         splice(@dbretrows,0,1);
         }
      until ($dbretrows[0] !~/^ *$/) {
         splice(@dbretrows,0,1);
         }
      #save off the header strings to be displayed just before the data
      $qhstring1="$dbretrows[0]";
      $qhstring2="$dbretrows[1]";
      splice(@dbretrows,0,3);
      }#if ($resultcount==1 && $skipsort==0)
   &sortby($tscrollx,$tscrolly);
   }#sub run_query

#connect with server and execute a DB command using the isql or sqsh binary
sub run_isql_cmd {
   $queryheader->packForget;
   &set_command_state;
   my $usecmd="";
   #if the maxrowcount is 0, dont set one
   if ($maxrowcount>0) {
      $usecmd="set rowcount $maxrowcount\ngo";
      }
   #if the database field is not default, set it
   if ($dbuse !~ /default/i) {
      $usecmd.="\nuse $dbuse\ngo";
      }
   if ($method eq "Isql") {
      $sqlbinary=$isqlbinary;
      }
   if ($method eq "Sqsh") {
      $sqlbinary=$sqshbinary;
      }
   @dbretrows=`$sqlbinary -U$dbuser -P$dbpass -S$dbserver -w999 <<EOD\n$usecmd\n$sqlstring\ngo\nEOD`;
   $queryout->insert('end',"\ @dbretrows");
   if ($tscrollx>-1 && $tscrolly>-1) {
      $queryout->xview(moveto=>$tscrollx);
      $queryout->yview(moveto=>$tscrolly);
      }
   }#sub run_isql_cmd

#set the busy LED to red
sub setbusy {
   $busymarker->configure(-background=>$busycolor);
   $LW->update;
   $alarmstring="";
   }

#return the busy LED to green
sub setunbusy {
   $busymarker->configure(-background=>$unbusycolor);
   $LW->update;
   }

#configure colors to make these labels and the sort checkboxes available
sub set_query_state {
   $queryheader->pack(@headerinfo);
   $queryout->pack(@datainfo);
   $colnumlabel->configure(-foreground=>$txtforeground);
   $rownumlabel->configure(-foreground=>$txtforeground);
   $revsortbutton->configure(-state=>'normal',-selectcolor=>'red4');
   $numsortbutton->configure(-state=>'normal',-selectcolor=>'red4');
   $sumbutton->configure(-state=>'normal');
   #the tag for the data type row 
   $queryheader->tag('add','dbtype',"2.0","2.0 + 1 line");
   $queryheader->tag('configure','dbtype',-foreground=>$datatypeforeground);
   #manually set the history for sortby and move the display back to where it was previously, also
   #make sure the width is set, otherwise, the menubutton will resize and mess up the execute button
   my @empty="";
   #sometimes the menu would be doubled up - caused by invoking the menubutton when it is configured.
   #clearing them menu and then reconfiguring it works around this behavior.  ugh..
   $sortbyentry->configure(-options=>\@empty,-width=>24,-justify=>'left');
   $sortbyentry->configure(-state=>'normal',-options=>\@sortbyhist);
   $sortbutton->configure(-state=>'normal');
   }#sub

#configure colors to make these labels and the sort checkboxes unavailable
sub set_command_state {
   $queryheader->packForget;
   $queryout->pack(@datainfo);
   $sortby=" ";
   $sortbutton->configure(-state=>'disabled');
   $revsortbutton->configure(-state=>'disabled',-selectcolor=>$buttonbackground);
   $numsortbutton->configure(-state=>'disabled',-selectcolor=>$buttonbackground);
   $sumbutton->configure(-state=>'disabled');
   $colnumlabel->configure(-foreground=>'grey65');
   $rownumlabel->configure(-foreground=>'grey65');
   $dbrowcount="";
   $dbcolcount="";
   $sortbyentry->configure(-width=>24,-justify=>'left',-state=>'disabled',-activebackground=>$buttonbackground,-options=>\@empty);
   #set the skipsort flag to 0 for the next time that a db command is executed.
   #the manual override for sorting only lasts for one command execution
   $skipsort=0;
   }#sub

#the sort routine can be called standalone, so it is splitout of the run_query routine,
#it performs more than just the sort.  It is also responsible for populating the text
#widget $queryout and $queryheader
sub sortby {
   ($tscrollx,$tscrolly)=@_;
   if (!$tscrollx) {$tscrollx=0};
   if (!$tscrolly) {$tscrolly=0};
   #execute the sort ONLY if 1 result set has been returned and the skipsort flag is 0
   if ($resultcount==1 && $skipsort==0) {
      &setbusy;
      if (grep(/^\Q$sortby\E$/,@sortbyhist)) {
         # we have to figure what element of the sortbyhist array the sort parameter is..
         $sortindex=0;
         foreach (@sortbyhist){
            $sortindex++;
            #if we find the sort parameter in the sortbyhist array, exit the loop
            last if (/^\Q$sortby\E$/);
            }#foreach @sortbyhist
         }else{
            $sortindex=0;
            $sortby=$sortbyhist[0];
            }#else if grep sortby..
      #if the numeric flag is set, sort differently
      if ($numsort) {
         $sortindex.="n";
         }
      #if the reverse flag is set, sort differently again
      if ($reversesort) {
         $sortindex="\-$sortindex";
         }
      #dont really execute the sort unless the sortby variable is set.  This is to keep
      #from double sorting.  Once when sortby is called and again when the sortbyentry
      #optionmenu is configured with the sort items
      if ($sortby&&$sortoverride==0) {
         #Actually execute the sort
         @dbretrows=fieldsort '\|',[$sortindex],@dbretrows;
         }#if sortby
      #since we can now override the sort, scan the entire results for a null line or a
      #line of spaces and remove them from the data.  When the sort was always forced,
      #these rows were always at the start of the data, now they are not
      for($x=0; $x<=$#dbretrows; ++$x) {
         if ($dbretrows[$x]=~/^\s*$/) {
            splice(@dbretrows,$x,1);
            $x--;
            }#if
         }#for
      #populate the header just before the data fields
      $queryheader->delete('0.0','end');
      $queryheader->insert('end',"$qhstring1\n$qhstring2");
      }else {
         #take off the first row if null and resultcount is >1
         if ($dbretrows[0]=~/^ *$/) {
            splice(@dbretrows,0,1);
            }#if
         }#else if resultcount ==1;
   $dbretrows[0]=~s/ *\n//;
   #post the results regardless of whether or not a sort is being executed
   $queryout->delete('0.0','end');
   $queryout->insert('end',"@dbretrows\n");
   #check the header to see if it contains any real data.  This is for those sp_commands that only
   #return one resultset, but dont have a  structured table style output, therefore we need to treat
   #the data like a command not a table.   ex - sp_lock
   $_=$queryheader->get('2.0','end');
   #if only one result was returned set the query state, otherwise set the command state
   if ($resultcount==1&&$_=~/\w/) {
      &set_query_state;
      #set the rowcount variable... If the first row of data is null, leave rowxount at 0
      $dbrowcount=($#dbretrows);
      if ($dbretrows[0] ne "") {
         $dbrowcount++;
         }
      #count the columns by counting the column seperator in the first row of data in the header
      #$dbcolcount=(split(/\|/,"$testhdata")-1);
      $dbcolcount=0;
      $dbcolcount += tr/|/|/;
      if ($dbcolcount <0) {
         $dbcolcount=0;
         }
      }else{
         &set_command_state;
         }
   #if the scrollbars have been moved, set the display back where it was
   if ($tscrollx>-1 && $tscrolly>-1) {
      $queryheader->xview(moveto=>$tscrollx);
      $queryout->xview(moveto=>$tscrollx);
      $queryout->yview(moveto=>$tscrolly);
      }
   #highlight the headers for each result set if more than one is returned
   if ($resultcount>1 && $method eq "DBI/DBD") {
      $srchstring='\-';
      #delete any old tags so new ones will show
      $queryout->tag('remove','header', qw/0.0 end/);
      $current='0.0';
      while (1) {
         $current=$queryout->search(-regexp,'^------+ \|',$current,'end');
         last if (!$current);
         $queryout->tagAdd('header',"$current -2 line","$current +1 line");
         $queryout->tag('configure','header',
            -foreground=>$headerforeground,
            );
         $current=$queryout->index("$current + 1 line");
         }#while true
      }#if resultcount>1 &&...
   &setunbusy;
   }#sub sortby

#total up the sortby column
sub total_col {
   if (grep(/^\Q$sortby\E$/,@sortbyhist)) {
   # we have to figure what element of the sortbyhist array the sort parameter is..
   $sumindex=0;
   foreach (@sortbyhist){
      $sumindex++;
      #if we find the sort parameter in the sortbyhist array, exit the loop
      last if (/^\Q$sortby\E$/);
      }#foreach @sortbyhist
   }else{
      $sumindex=0;
      }#else if grep sortby..
   $sum=0;
   foreach (@dbretrows) {
      my $t=(split("\\| +","$_"))[$sumindex-1];
      #skip the itme if it is blank
      next if ($t=~/^ *$/);
      #if the column contains any data that is not an integer or a float, skip it
      next if ($t!~/^\d+ *$|^\d+\.\d+ *$/);
#       {
#         $sum="N\\A";
#          next;
#         last;
#         }
      $sum+=$t;
      }
   $alarmstring="    \'$sortby\' Total: $sum";
   }
   
#write out the returned query information to an ascii file
sub savit {
   my ($outfile)=@_;
   if ($outfile eq "") {
      $savebutton->configure(-state=>'normal');
      my @types =
      (["Out files ",          ['.out']],
       ["Text files",          ['.txt']],
       ["All files ",          ['*']],
      );
   #cant get the filedialog colors to look right..   setting the label option helps
   $LW->optionAdd("*Label*Background", "$background");
   $outfile=$LW->getSaveFile(
      -filetypes        => \@types,
      -initialfile      => 'dbgui.out',
      -defaultextension => '.out',
      );
   $LW->optionAdd("*Label*Background", "$labelbackground");
   #if the save dialog was canceled off, dont continue
   return if ($outfile eq "");
   }
   my $date=localtime(time());
   open(outfile, ">$outfile") || die "Can't open save file :$outfile";
   print outfile "\nReport created $date";
   print outfile "Query Data:";
   print outfile "  Server Name - $dbserver";
   print outfile "     Username - $dbuser";
   print outfile "Database Name - $dbuse";
   if ($maxrowcount) {
      print outfile "Max Row Count - $maxrowcount";
      }
   foreach ("querystring1","querystring2","querystring3") {
      #check to see which of the sql strings is enabled with the checkbutton
      #only print the enabled ones
      $qsmark=substr($_,-1);
      $qsmark="qsactive$qsmark";
      if (${$qsmark}==1) {
         print outfile " Query String - ${$_}";
         }
      }#foreach
   print outfile "Rows Returned - $dbrowcount";
   print outfile "Cols Returned - $dbcolcount\n";
   print outfile "Returned Data:\n";
   my $queryhsave=$queryheader->get('0.0','end');
   my $querydsave=$queryout->get('0.0','end');
   $queryhsave=~s/\n+$//;
   chomp $querydsave;
   print outfile "$queryhsave";
   #create a divider line to go in the output report between the header and data lines
   my $thsave=$queryheader->get('0.0','2.1');
   my $divider="";
   for($i = 1; $i < (length($thsave)-2); ++$i) {
      $divider.="-";
      }
   print outfile "$divider";
   print outfile "$querydsave";
   close outfile;
   }#sub savit

#write out the clone window data to an ascii file
sub clone_savit {
   my ($cloneoutfile)=@_;
   if ($cloneoutfile eq "") {
      $clonesavebutton->configure(-state=>'normal');
      my @types =
      (["Log files ",          ['.out']],
       ["Text files",          ['.txt']],
       ["All files ",          ['*']],
      );
   $LW->optionAdd("*Label*Background", "$background");
   $cloneoutfile=$LW->getSaveFile(
      -filetypes        => \@types,
      -initialfile      => 'clone_dbgui.out',
      -defaultextension => '.out',
      );
   $LW->optionAdd("*Label*Background", "$labelbackground");
   #if the save dialog was canceled off, dont continue
   return if ($cloneoutfile eq "");
   }
   my $date=localtime(time());
   open(outfile, ">$cloneoutfile") || die "Can't open save file :$cloneoutfile";
   print  outfile "\nCloned Data Report created $date\n\nQuery Data:";
   print outfile "$clonestat\n";
   my $mytempcmd=$cldbcmd->entrycget('end',-label);
   print outfile " DBCmd - $mytempcmd";
   print outfile "\nReturned Data:\n";
   my $clqueryhsave=$cloneheader->get('0.0','end');
   $clqueryhsave=~s/\n+$//;
   chomp $clqueryhsave;
   print outfile "$clqueryhsave";
   #create a divider line to go in the output report between the header and data lines
   my $clthsave=$cloneheader->get('0.0','2.1');
   my $cldivider="";
   for($i = 1; $i<(length($clthsave)-2); ++$i) {
      $cldivider.="-";
      }
   print outfile "$cldivider";
   my $clquerydsave=$clonewin->get('0.0','end');
   print outfile "$clquerydsave";
   close outfile;
   }#sub clone_savit

#eval the snapshot string for the current snapshot variable value
sub run_snapshot {
   ($snapnum)=@_;
   $tsnap="snapshot$snapnum";
   (eval $$tsnap);
   #once the snapshot string has been executed, pull the single quotes off of the query strings
   #otherwise, everytime a snapshot is executed, the slashes start stacking up, we dont want
   #the slashes displayed in the GUI, only in the checkpoint file
   foreach ($querystring1,$querystring2,$querystring3) {
      $_ =~ s/\\'/\'/g;
      $_ =~ s/\\"/\"/g;
      $_ =~ s/\\@/\@/g;
      }
   &act_deactivate("qsentry1","qsactive1");
   &act_deactivate("qsentry2","qsactive2");
   &act_deactivate("qsentry3","qsactive3");
   }#sub run snapshot

#capture the snapshot string to be saved
sub take_snapshot {
   my ($snapnum)=@_;
   my $tsnap="snapshot$snapnum";
   foreach ($querystring1,$querystring2,$querystring3) {
      #replace any slashes with an escaped quote with a three slashes and a single quote
      #needed to properly save the values off in the checkpoint file
      $_ =~ s/\\*\'/\\\'/g;
      #substitute double quotes for escaped ones
      $_=~s/\\*\"/\\\"/g;
      }

   #collect all other variables for the snapshot string
   my $snapshotstring="";
   foreach (@variablelist) {
      next if (/^snapshot/);
      $snapshotstring.="\$$_=\'$$_\'\;"
      }
   ${$tsnap}=$snapshotstring;
   &run_snapshot("$snapnum");
   }#sub snapshot

sub checkpoint {
   #write out the checkpoint file for the next time the utility is started
   open(ckptfile, ">$checkpointfile") or die "Can't open checkpoint file - $checkpointfile";
   print ckptfile "\#Checkpoint file for dbgui.pl utility";
   print ckptfile "\#Query parameters and histories are saved on exit and restored on startup\n";
   print ckptfile "\#NOTE - Snapshot0 is used to set the variables on application startup, but";
   print ckptfile "\#the variables have to be initialized for the ComboEntries..  therefore they";
   print ckptfile "\#are set to null initially and redifined from Snapshot0..\n";

   #Snapshot 0 is always the state the utility was last left if exited properly.
   #Since snapshot 0 will be restored on startup, there is no need to record any variables
   #that are not the snapshot strings - however if the variables are not initialized,
   #the history arrays will get lost the next time the utility is started, so I write all
   #variables to the checkpoint file as empty even though they are redefined with snapshot0
   &take_snapshot("0");
   #since the variables can contain dollar signs (like in sp_helptext commands)
   #etc... escape the special characters
   foreach (@variablelist) {
      if (!/^snapshot/) {
         my $snapvar=${$_};
         #substitute @ signs for excaped ones
         $snapvar=~s/@/\\@/g;
         print ckptfile "\$$_=\"${$snapvar}\"\;";
         }else{
            if ("${$_}" ne "") {
               print ckptfile "\$$_=q\($$_\)\;";
               }else{
                   #the snapshot variable is empty - write out null definitions for each variable
                   $snapshotstring="$_\=q\(";
                   foreach (@variablelist) {
                      next if (/^snapshot/);
                      $snapshotstring.="\$$_=\'\'\;"
                      }#foreach
                    ${$_}=$snapshotstring;
                    print ckptfile "\$${$_}\)\;";
                   }#else
             }#first else
      }#foreach variablelist
   foreach $arrayname (@arraylist) {
      my $arraystring="\@$arrayname=(\n";
      foreach (@{$arrayname}) {
         #substitute double quotes for escaped ones
         $_=~s/\\*\"/\\\"/g;
         #substitute @ symbols for escaped ones
         $_=~s/\\*\$/\\\$/g;
         #substitute @ symbols for escaped ones
         $_=~s/\\*\@/\\\@/g;
         $arraystring.="\"$_\",\n";
         }
      $arraystring.="\);";
      print ckptfile "\n$arraystring";
      }
   print ckptfile "\n1\;";
   close ckptfile;
   }

#configure the query strings to be greyed or black depending on their execute state set
#by the checkbuttons
sub act_deactivate {
   my ($querywid,$queryline)=@_;
   #I have to check to see if the widgets actually exist before configuring them,
   #this is to handle problems running snapshow when a clean .dbgui file is being
   #created on startup.
   if (${$querywid}) {
      if (${$queryline} eq "1") {
         ${$querywid}->configure(-fg=>$txtforeground);
         ${$querywid}->focus;
         }else{
            ${$querywid}->configure(-fg=>'grey65');
            }#else
      ${$querywid}->update;
      }
   }#sub

#query results search dialog
sub searchit {
   $srchstring="";
   $SW->destroy if Exists($SW);
   $SW=new MainWindow(-title=>'DBGUI search');

   #set some nice parameters to be inherited by the search histentry
   $SW->optionAdd("*background","$background");
   $SW->optionAdd("*frame*relief", "flat");
   $SW->optionAdd("*font", "8x13bold");

   #width,height in pixels
   $SW->minsize(424,51);
   $SW->maxsize(724,51);

   #default to non case sensitive
   $caseflag="nocase";
   $newsearch=1;

   #The top frame for the text
   my $searchframe1=$SW->Frame(
      -borderwidth=>'0',
      -relief=>'flat',
      -background=>$background,
      )->pack(
         -expand=>1,
         -fill=>'both',
         );

   my $searchframe2=$SW->Frame(
      -borderwidth=>'0',
      -relief=>'flat',
      -background=>$background,
      )->pack(
         -fill=>'x',
         -pady=>2,
         );

    $searchframe1->Checkbutton(
      -variable=>\$caseflag,
      -font=>$winfont,
      -relief=>'flat',
      -text=>"Case",
      -highlightthickness=>0,
      -highlightcolor=>'black',
      -activebackground=>$background,
      -bg=>$background,
      -foreground=>$txtforeground,
      -borderwidth=>'1',
      -width=>6,
      -offvalue=>"nocase",
      -onvalue=>"case",
      -command=>sub{$current='0.0',$searchcount=0;$newsearch=1},
      -background=>$background,
      )->pack(
         -side=>'left',
         -expand=>0,
         );

   my $searchhistframe=$searchframe1->Frame(
      -borderwidth=>1,
      -relief=>'sunken',
      -background=>$background,
      -foreground=>$txtforeground,
      -highlightthickness=>0,
      )->pack(
         -side=>'bottom',
         -expand=>0,
         -pady=>0,
         -padx=>1,
         -fill=>'x',
         );

    $ssentry=$searchhistframe->HistEntry(
      -font=>$winfont,
      -relief=>'sunken',
      -textvariable=>\$srchstring,
      -highlightthickness=>0,
      -highlightcolor=>'black',
      -selectforeground=>$txtforeground,
      -selectbackground=>'#c0d0c0',
      -background=> 'white',
      -bg=>$background,
      -foreground=>$txtforeground,
      -borderwidth=>0,
      -bg=> 'white',
      -limit=>$histlimit,
      -dup=>0,
      -match => 1,
      -justify=>'left',
      -command=>sub{@searchhist=$ssentry->history;},
      )->pack(
         -fill=>'both',
         -expand=>0,
         );

   #press enter and perform a single fine
   $ssentry->bind('<Return>'=>\&find_one);
   $ssentry->history([@searchhist]);

   $searchframe2->Button(
      -text=>'Find',
      -borderwidth=>'1',
      -width=>'6',
      -background=>$buttonbackground,
      -foreground=>$txtforeground,
      -highlightthickness=>0,
      -font=>$winfont,
      -command=>\&find_one,
      )->pack(
         -side=>'left',
         -padx=>0,
         );

   $searchframe2->Button(
      -text=>'Find All',
      -borderwidth=>'1',
      -width=>'6',
      -background=>$buttonbackground,
      -foreground=>$txtforeground,
      -highlightthickness=>0,
      -font=>$winfont,
      -command=>\&find_all,
      )->pack(
         -side=>'left',
         -padx=>1,
         );

   $searchframe2->Button(
      -text=>'Cancel',
      -borderwidth=>'1',
      -width=>'6',
      -background=>$buttonbackground,
      -foreground=>$txtforeground,
      -highlightthickness=>0,
      -font=>$winfont,
      -command=>sub{$SW->destroy;$queryout->tag('remove','search', qw/0.0 end/);}
      )->pack(
         -side=>'right',
         -padx=>2,
         );
   $ssentry->invoke;
   $ssentry->focus;
} # sub search

# search the Logfile for a term and return a highlighted line containing the term.
sub find_all {
   return if ($srchstring eq "");
   $ssentry->invoke;
   #delete any old tags so new ones will show
   $queryout->tag('remove','search', qw/0.0 end/);
   $current='0.0';
   $stringlength=length($srchstring);
   $searchcount=0;
   while (1) {
      if ($caseflag eq "case") {
         $current=$queryout->search(-exact,"$srchstring",$current,'end');
         }else{
            $current=$queryout->search(-nocase,"$srchstring",$current,'end');
            }#else
      last if (!$current);
      $queryout->tag('add','search',$current,"$current + $stringlength char");
      $queryout->tag('configure','search',
         -background=>'chartreuse',
         -foreground=>'black',
         );
      $searchcount++;
      $current=$queryout->index("$current + 1 char");
      }#while true
      #no matches were found - set the titlebar
   if ($searchcount==0) {
      $SW->configure(-title=>"No Matches");
      }else{
         $SW->configure(-title=>"$searchcount Matches");
         }
}#sub find all

#find and highlight one instance of the search string at a time
sub find_one {
   return if ($srchstring eq "");
   $ssentry->invoke;
   $queryout->tag('remove','search', qw/0.0 end/);
   #mull through the text tagging the matched strings along the way
   if ($srchstring ne $srchstringold || $newsearch==1) {
      $allcount=0;
      $tempcurrent='0.0';
      $srchstringold=$srchstring;
      while (1) {
         if ($caseflag eq "case") {
            $tempcurrent=$queryout->search(-exact,"$srchstring",$tempcurrent,'end');
            }else{
               $tempcurrent=$queryout->search(-nocase,"$srchstring",$tempcurrent,'end');
               }#else
         last if (!$tempcurrent);
         $allcount++;
         $tempcurrent=$queryout->index("$tempcurrent + 1 char");
         $searchcount=0;
         $current='0.0';
         }#while true
     $newsearch=0;
    }#if srchstring ne srstringold
   #set the titlebar of the search dialog to indicate the matches
   $SW->configure(-title=>"$allcount Matches");
   $stringlength=length($srchstring);
   if (!$current) {
      $current='0.0';
      $searchcount=0;
      } # if current
   if ($caseflag eq "case") {
      $current=$queryout->search(-exact,$srchstring,"$current +1 char");
      }else{
         $current=$queryout->search(-nocase,$srchstring,"$current +1 char");
         }#else
   #no matches were found - set the titlebar
   if ($current eq "") {
      $SW->configure(-title=>"No Matches");
      return;
      }
   $current=$queryout->index($current);
   $queryout->tag('add','search',$current,"$current + $stringlength char");
   $queryout->tag('configure','search',
      -background=>'chartreuse',
      -foreground=>'black',
      );
   $queryout->see($current);
   #see where the display has horizontally scrolled and move the header text to match
   ($tscrollx,$rest)=$queryout->xview;
   $queryheader->xview(moveto=>$tscrollx);
} #sub find one

sub alarm_handler {
   print "Timer expired.. Cleaning up.";
   $alarmstring=" **  Incomplete Data - Timer Expired  **";
   $sth->finish;
   #if no data is being returned from the server, currently there is no way
   #to force the process down.
   if (!$dbdata) {
      print "No data has been returned, forcing a stop of the command";
      $sth->cancel;
      exit;
      }
}#sub

#error handler taken from subutil.pl in the sybperl distribution.  Needed to trap
#the error strings returned for non DB type errors
sub err_handler {
   my ($err, $severity, $state, $line, $server, $proc, $msg)= @_;
   #print "ERROR Handler ($err, $severity, $state, $line, $server, $proc, $msg)";
   # Check the error code to see if we should report this.
   if ($severity >=10 && $err>0) {
      $msg=wrap(" "," ","$msg");
      $skipsort=1;
      $queryout->insert('end',"Error:$err\nProcedure:$proc\nLine:$line\nState:$state\nSeverity:$severity\n\n$msg\n");
      #I have to push the error text onto the retrows array for errors
      push(@dbretrows,"Error:$err\nProcedure:$proc\nLine:$line\nState:$state\nSeverity:$severity\n\n$msg\n");
      alarm();
      &set_command_state;
      &setunbusy;
      }

   #handle data that is returned from a print statement like form the sp_helpcode proc
   if ($err==0 && $msg !~/^ *$/) {
      return if ($msg =~/^Message empty/);
      push(@dbretrows,"$msg");
      $skipsort=1;
      return 0;
      }
}#sub error_handler

#create a printdialog to collect options before sending to a printer
sub printdialog {
   #save the data to a tempfile for printing
   &savit("/tmp/dbgui.prt");
   ## Create the toplevel window
   $printwin->destroy if Exists($printwin);
   $printwin = Tk::MainWindow->new;
   $printwin->minsize(375, 243);
   $printwin->maxsize(375, 243);
   $printwin->optionAdd("*font", "$winfont");
   $printwin->optionAdd("*background","$background");
   $prt_opt_f=$printwin->Frame( 
      -relief=>'raised', 
      -borderwidth=>'1',
      -background=>$background,  
      )->pack( 
         -side=>'top', 
         -anchor=>'w', 
         -fill=>'both', 
         -expand=>'yes',
         );

   $prt_opt_f->Frame( 
      -relief=>'flat', 
      -borderwidth=>'0',
      -background=>$background,
      -height=>5,  
      )->pack( 
         -side=>'top', 
         -fill=>'x', 
         -expand=>'no',
         );

   $printer_f=$prt_opt_f->Frame(
      -relief=>'flat', 
      -borderwidth=>'1',
      -background=>$background,  
      )->pack( 
         -side=>'left', 
         -anchor=>'w', 
         -fill=>'both', 
         -expand=>'yes',
         );

   $options_f=$prt_opt_f->Frame(
      -relief=>'flat', 
      -borderwidth=>'1',
      -background=>$background,  
      )->pack( 
         -side=>'left', 
         -anchor=>'w', 
         -fill=>'both',
         );

   $buttons_f=$printwin->Frame(
      -relief=>'raised', 
      -borderwidth=>'1',
      -background=>$background,  
         )->pack( 
         -side=>'top', 
         -anchor=>'e', 
         -fill=>'both', 
         -expand=>'yes',
         );

   $status_f=$printwin->Frame(
      -relief=>'flat', 
      -borderwidth=>'1',
      -background=>$background,  
         )->pack( 
         -side=>'top', 
         -anchor=>'e', 
         -fill=>'both', 
         -expand=>'yes',
         );

#############################################################################
  # Create Printer, Font and Size Selection Frame Contents

   $prt_f=$printer_f->Frame(
      -background=>$background,
      )->pack( 
         -side=>'top',
         );

  $prt_f->Label(
      -text=>"  Printer:",
      -background=>$background,
      -justify=>'right',
      )->pack( 
         -side=>'left',
         -pady=>2,
         );

   $prt_f->Optionmenu(
      -underline=>0,
      -relief=>'raised',
      -textvariable=>\$printer_set,
      -highlightthickness=>0,
      -borderwidth=>1,
      -background=>$buttonbackground,
      -width=>14,
      -options=>\@printers,
      -command=>\&check_printer,
         )->pack(-side=>'left',
         -padx=>'5',
         -pady=>2,
         );

   $size_f=$printer_f->Frame(
      -background=>$background,
      )->pack( 
         -side=>'top',
         );

   $size_f->Label(
      -text=>"Font Size:",
      -background=>$background,  
      -justify=>'right',
      )->pack( 
         -side=>'left',
         -pady=>2,
         );

  $size_f->Optionmenu(
      -underline=>0,
      -relief=>'raised',
      -textvariable=>\$size_set,
      -highlightthickness=>0,
      -borderwidth=>1,
      -background=>$buttonbackground,
      -width=>14,
      -options=>[qw(5 6 7 8 9 10 11 14 17 20 24)],
      )->pack(
         -side=>'left',
         -padx=>'5' ,
         -pady=>2,
         );

   # Create Filename Entry Frame Contents
   $psfile_f=$printer_f->Frame(
      -background=>$background,
      -borderwidth=>0,
      -relief=>'flat',
      )->pack( 
         -side=>'top',
         -pady=>2,
         );

   $psfile_f->Label( 
      -text=>"  Outfile:",
      -highlightthickness=>0,
      -borderwidth=>1,
      -background=>$background,
      )->pack( 
         -side=>'left',
         -pady=>2,
         );

   $file_e=$psfile_f->Entry(
      -textvariable=>\$printfile,
      -highlightthickness=>0,
      -borderwidth=>2,
      -background=>'white', 
      -width=>18,  
      -relief=>'sunken',
      )->pack(
         -side=>'left',
         -padx=>'5',
         );


   #############################################################################
   # Create Copies and Options Selection Frame Contents

   $options_f1=$options_f->Frame(  
      -background=>$background,
      )->pack( 
         -side=>'top', 
         -anchor=>'w', 
         -fill=>'both',
         );

   $options_f2=$options_f->Frame(  
      -background=>$background,
      )->pack( 
      -side=>'top', 
      -anchor=>'w', 
      -fill=>'both',
      );

   # Start the contruction
   $options_f1->Label(
      -text=>"Copies:",
      -highlightthickness=>0,
      -borderwidth=>1,
      -background=>$background,
      )->pack(
         -side=>'left',
         ); 

   $options_f1->Entry(
      -textvariable=>\$copies,
      -highlightthickness=>0,
      -borderwidth=>1,
      -background=>'white',
      -width=>3,
      )->pack(
         -side=>'left',
         );

   $options_f2->Frame(
      -background=>$background,
      -height=>3,
      )->pack(
         -side=>'top', 
         -anchor=>'w',
         );

   $options_f2->Checkbutton(
      -text=>"Landscape   ",
      -background=>$background,
      -relief=>'flat',
      -highlightthickness=>0,
      -borderwidth=>1,
      -variable=>\$CkBtn1_set,
      -justify=>'left',
      )->pack(
         -side=>'top', 
         -fill=>'x', 
         -expand=>'no',
         );

   $options_f2->Checkbutton(
      -text=>"2-Columns   ",
      -background=>$background,
      -relief=>'flat',
      -highlightthickness=>0,
      -borderwidth=>1,
      -variable=>\$CkBtn2_set,
      )->pack(
         -side=>'top', 
         -fill=>'x', 
         -expand=>'no',
         );

   $options_f2->Checkbutton(
      -text=>"Line Numbers",
      -background=>$background,
      -relief=>'flat',
      -highlightthickness=>0,
      -borderwidth=>1,
      -variable=>\$CkBtn3_set,
      )->pack(
         -side=>'top', 
         -fill=>'x', 
         -expand=>'no',
         );

   $options_f2->Checkbutton(
      -text=>"No Title    ",
      -relief=>'flat',
      -background=>$background,
      -relief=>'flat',
      -highlightthickness=>0,
      -borderwidth=>1,
      -variable=>\$CkBtn4_set,
      )->pack(
         -side=>'top', 
         -fill=>'x', 
         -expand=>'no',
         );

   $options_f2->Checkbutton(
      -text=>"Truncate    ",
      -background=>$background,
      -relief=>'flat',
      -highlightthickness=>0,
      -borderwidth=>1,
      -variable=>\$CkBtn5_set,
      )->pack(
         -side=>'top', 
         -fill=>'x', 
         -expand=>'no',
         );

   #############################################################################
   # Create Button Frame Contents

   $buttons_f->Button(
      -background=>$buttonbackground,
      -text=>'Cancel',
      -borderwidth=>1,   
      -highlightthickness=>0,
      -command=>sub{$printwin->destroy;unlink("/tmp/dbgui.prt")},
      )->pack(
         -side=>'left', 
         -expand=>'yes', 
         -pady =>'10',
         );

   my $def_btn=$buttons_f->Frame(
      -relief=>'sunken',
      -borderwidth=>1,
      -background=>$background,
      )->pack(
         -side=>'left', 
         -expand=>1,
         );

   $def_btn->Button(
      -background=>$buttonbackground,
      -text=>'Print',
      -borderwidth=>1,
      -highlightthickness=>0,  
      -command=>\&Do_Print,
      )->pack(
         -padx=>'1m', 
         -pady=>'1m',
         );

   #############################################################################
   # Create Status Frame Contents

   $status_f->Label(
      -text=>'Print Status: ',
      -background=>$background,
      )->pack(
         -side=>'top',
         -anchor=>'w',
         );

   $scrolly=$status_f->Scrollbar(
      -orient=>'vert',
      -borderwidth=>0,
      -elementborderwidth=>1,
      -highlightthickness=>0,
      -background=>$buttonbackground,
      -troughcolor=>$background,
      -relief=>'flat',
      )->pack(
         -side=>'right',
         -fill=>'y',
         -padx=>0,
         -pady=>0,
         );

   $status_t=$status_f->ROText(
      -yscrollcommand=>['set', $scrolly],
      -height=>4, 
      -relief=>'sunken', 
      -width=>'45',
      -highlightthickness=>0,
      -borderwidth=>1,
      -background=>'white',
      )->pack(
         -side=>'top',
         -fill=>'x',
         -expand=>'yes',
         -padx=>1,
         -pady=>2,
         );

   $scrolly->configure(-command=>['yview', $status_t]);
   &check_printer;
}#sub

#check the printer definition.  If it is set to a file, enable the file entry
sub check_printer {
  if ($printer_set =~ /Print to File/i) {
      $file_e->configure(-state=>normal,-foreground=>$txtforeground) if Exists($file_e);
      }else{
          $file_e->configure(-state=>disabled,-foreground=>'grey65') if Exists($file_e);
          }#else
}#sub


#send the file to the printer
sub Do_Print {
   $status_t->delete('0.0','end');
   $status_t->update;
   my $en_opts="";

   $en_opts .= "-r " if ($CkBtn1_set == 1);
   $en_opts .= "-2 " if ($CkBtn2_set == 1);
   $en_opts .= "-C " if ($CkBtn3_set == 1);
   $en_opts .= "-B " if ($CkBtn4_set == 1);
   $en_opts .= "-c " if ($CkBtn5_set == 1);
   $en_opts .= "-n$copies" if ($copies ne "");

    if ($printer_set =~ /Print to File/i && $printfile !~/^ *$/) {
       $Status=`$psprint $en_opts -f$size_set -o$printfile /tmp/dbgui.prt 2>&1`;
       $status_t->insert('1.1', $Status);
       }else{
          $Status=`$psprint $en_opts -f$size_set -P$printer_set /tmp/dbgui.prt 2>&1`;
          $status_t->insert('1.1', $Status);
          }#else
}#sub 

