#! perl -w
###############################################################################
# o32BGCTool  (derived from BGCTool v0.07)
# v1.00:

# TO DO:
###############################################################################

#a comment on the HC06 BT module
#changes of the Parity with AT+PN, AT+PE, AT+PO become effective only after the next power up
#with parity the BT module does work together with stmflashloder!!!!


use strict;
#no warnings 'deprecated';
use Win32;
use Win32::GUI();
use Win32::GUI::Constants qw( /^WS_/ );
my ($PerlWindow) = Win32::GUI::GetPerlWindow();
Win32::GUI::Hide($PerlWindow);

use Win32::SerialPort 0.22;
use Switch;
use Win32API::File qw(QueryDosDevice); #produces error: (in cleanup) Can't call method "FETCH" on an undefined value at C:/Perl/site/lib/Win32/GUI.pm line 3480 during global destruction.
use Config::IniFiles;
use File::Basename;
use Cwd 'abs_path';
use Win32::GUI::TabFrame;
use Win32::GUI::BitmapInline ();
#use PDL;

my $VersionStr= '1. Oct. 2014 v0.46';

#CAREFULL: in Data Display version is not double checked!
my @SupportedBGCLayoutVersions= ( '46' ); #layout versions supported by o32BGCTool, used in ExecuteHeader()

my @STorM32BGCBoardList= (
{
  name => 'STorM32 BGC v1.3 with F103RC',
  uc => 'F103RC',
  hexfile => 'storm32bgc_v130_f103rc',
},{
  name => 'STorM32 BGC v1.2 with F103RC',
  uc => 'F103RC',
  hexfile => 'storm32bgc_v120_f103rc',
},{
  name => 'STorM32 BGC v1.1 with F103RC',
  uc => 'F103RC',
  hexfile => 'storm32bgc_v110_f103rc',
}
);

my @FirmwareVersionList= ( 'v0.46','v0.43e','v0.41e','v0.33', ); #versions available in the flash tab selector




my $BGCStr= "o323BGC";

my $BGCToolRunFile= $BGCStr."Tool_Run";

my @STM32ProgrammerList= ( 'ST-Link/V2 SWD', 'System Bootloader @ UART1' );

my $STLinkIndex= 0;
my $SystemBootloaderIndex= 1;

my $ErrorStr= '';

my $ExePath= dirname(abs_path($0));
$ExePath=~ tr/\//\\/;



#---------------------------
# ALWAYS finish with a retrun value in Event Handlers!
# 1: Proceed, taking the default action defined for the event.
# 0: Proceed, but do not take the default action.
# -1: Terminate the message loop.
#---------------------------

###############################################################################
# Allgemeine Resourcen

#my $StdWinFont= Win32::GUI::Font->new(-name=>'Tahoma',-size=>8,);  #good, but not exactly it
#my $StdWinFont= Win32::GUI::Font->new(-name=>'Segoe UI',-size=>7,); #good, but not exactly it

#my $StdWinFont= Win32::GUI::Font->new(-name=>'Verdana',-size=>8,);  #solala, but not exactly it
#my $StdWinFont= Win32::GUI::Font->new(-name=>'Consolas',-size=>8,);  #no
#my $StdWinFont= Win32::GUI::Font->new(-name=>'Courier',-size=>7,);  #no
#my $StdWinFont= Win32::GUI::Font->new(-name=>'Lucida Console',-size=>9,); #no
#my $StdWinFont= Win32::GUI::Font->new(-name=>'Arial',-size=>8,); #this is it not!
#my $StdWinFont= Win32::GUI::Font->new(-name=>'Calibri',-size=>9,); #this is it not!

#my $StdTextFont= Win32::GUI::Font->new(-name=>'Lucida Console',-size=>10,);
my $StdHelpFont= Win32::GUI::Font->new(-name=>'Lucida Console',-size=>10,);

#In whatever language you are using, read the value for
#HKEY_CURRENT_USER \Control Panel\Desktop\WindowMetrics AppliedDPI
#The value returned for
#smaller: 96
#medium: 120
#larger: 144


#my $Icon = new Win32::GUI::Icon('BLHELITOOL.ICO');

#create from cmd line with
#perl -MWin32::GUI::BitmapInline -e "inline('BLHeliTool.ico')" >>script.pl
#http://perl-win32-gui.sourceforge.net/cgi-bin/docs.cgi?doc=bitmapinline
my $Icon = Win32::GUI::BitmapInline->newIcon( q(
AAABAAEAICAQAAEABADoAgAAFgAAACgAAAAgAAAAQAAAAAEABAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAA6PToATlBPAEJaPwBhZGIAbXBuAHl8egBeilwAhYiGAI+SkACJo38Am56cAK+zsACR0aEA
yMvJAO3w7gAAAAAA//////////hBf///////////qIqP/4iBEBr/dzM0eP//9BEBFHgRAYEV9QAA
ABiP/zNLqEEBMRCqM1AAAAAUj/8TSqvdoLowAAAAEREAE///E0vd3dEBGlAF8wAAQT///xNNu73d
u92FFRFF/xf///8UXd3dvd3eux////RP////E6693d3d3dsf///xj////xPbmZmbve3bD///hP//
//8U2mZmZmC92x///zj/////EdoRImZh3bof//84/////xXd3bhRJL2KH///OP////8Uu7q7u7u7
eh///zj/////Fbuoi7u7unof//84/////xR1V3i6irh6H///OP////8TW6iFd47rWB////Sv////
E4VFekW97kof///zf////xNHWoVXqt5IH///8Y////8TRVQ1VXq6SB////OP////FEdURUREREcf
///zj////xNbu4h3VERYH///84////8TW9u7qqqopx////N/////E127u6qqrCgf///xr////3q9
3burqqZXP///8///////q4p6qzFKpf///3T///////////hRBH////8V////////////9D/////x
f/////////////Nf////M//////////////xtf//UU//////////////+Dq3Ux//////////////
//+INY///////////h//8HAMA+AACAHAAAABwAAAA8AACAfAAADPwAAfn8AAH5/AAB8/wAAfP8AA
Hz/AAB8/wAAfP8AAHz/AAB8/wAAfn8AAH5/AAB+fwAAfn8AAH5/AAB+fwAAfn8AAH5/AAB+/8AA/
P//gfz//+f5///n8///48f//+Af///wf/w==
) );

#perl -MWin32::GUI::BitmapInline -e "inline('camera-orientations.bmp')"  >>script.pl;

#ImuOrientation no. = index in List
#ImuOrientation value =  if( no.>11 ) value= no. + 4 else value= no.;
my @ImuOrientationList=(
{ name => 'z0�',     axes => '+x +y +z',  value => 0, },
{ name => 'z90�',    axes => '-y +x +z',  value => 1, },
{ name => 'z180�',   axes => '-x -y +z',  value => 2, },
{ name => 'z270�',   axes => '+y -x +z',  value => 3, },

{ name => 'x0�',     axes => '+y +z +x',  value => 4, },
{ name => 'x90�',    axes => '-z +y +x',  value => 5, },
{ name => 'x180�',   axes => '-y -z +x',  value => 6, },
{ name => 'x270�',   axes => '+z -y +x',  value => 7, },

{ name => 'y0�',     axes => '+z +x +y',  value => 8, },
{ name => 'y90�',    axes => '-x +z +y',  value => 9, },
{ name => 'y180�',   axes => '-z -x +y',  value => 10, },
{ name => 'y270�',   axes => '+x -z +y',  value => 11, },

{ name => '-z0�',    axes => '+y +x -z',  value => 16, },
{ name => '-z90�',   axes => '-x +y -z',  value => 17, },
{ name => '-z180�',  axes => '-y -x -z',  value => 18, },
{ name => '-z270�',  axes => '+x -y -z',  value => 19, },

{ name => '-x0�',    axes => '+z +y -x',  value => 20, },
{ name => '-x90�',   axes => '-y +z -x',  value => 21, },
{ name => '-x180�',  axes => '-z -y -x',  value => 22, },
{ name => '-x270�',  axes => '+y -z -x',  value => 23, },

{ name => '-y0�',    axes => '+x +z -y',  value => 24, },
{ name => '-y90�',   axes => '-z +x -y',  value => 25, },
{ name => '-y180�',  axes => '-x -z -y',  value => 26, },
{ name => '-y270�',  axes => '+z -x -y',  value => 27, },
);

my @ImuChoicesList= ();
my $no= 0;
foreach my $orientation (@ImuOrientationList){
  push( @ImuChoicesList, 'no.'.$no.':  '.$orientation->{name}.'  '.AxesRemovePlus($orientation->{axes}) );
  $no++;
}

my @FunctionInputChoicesList= (
  'off', 'Rc-0', 'Rc-1', 'Rc-2', 'Rc2-0', 'Rc2-1', 'Rc2-2', 'Rc2-3', 'Pot-0', 'Pot-1', 'Pot-2',
  'Virtual-1', 'Virtual-2', 'Virtual-3', 'Virtual-4', 'Virtual-5', 'Virtual-6', 'Virtual-7', 'Virtual-8', 'Virtual-9', 'Virtual-10',
  'But switch', 'But latch',
  'Aux-0 switch', 'Aux-1 switch', 'Aux-2 switch', 'Aux-01 switch', 'Aux-012 switch',
  'Aux-0 latch', 'Aux-1 latch', 'Aux-2 latch', 'Aux-01 latch', 'Aux-012 latch',
);
my $FunctionInputMax= 32; #32;


sub OptionToSkip{
  my $Option= shift;
  if( uc($Option->{name}) eq uc('Firmware Version') ){ return 1; }
  if( uc($Option->{name}) eq uc('Name') ){ return 2; }
  if( uc($Option->{name}) eq uc('Board') ){ return 3; }
  return 0;
}

my @OptionV005List= (
{
  name => 'Firmware Version',
  type => 'OPTTYPE_STR+OPTTYPE_READONLY', len => 0, ppos => 0, min => 0, max => 0, steps => 0,
  size => 16,
  expert=> 0,
  column=> 1,
},{
  name => 'Board',
  type => 'OPTTYPE_STR', len => 16, ppos => 0, min => 0, max => 0, steps => 0,
  size => 16,
},{
  name => 'Name',
  type => 'OPTTYPE_STR', len => 16, ppos => 0, min => 0, max => 0, steps => 0,
  size => 16,

##--- MAIN tab --------------------
},{
  name => 'Low Voltage Limit',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 7, default => 1, steps => 1,
  size => 1,
  adr => 18,
  choices => [ 'off', '2.9 V/cell', '3.0 V/cell', '3.1 V/cell', '3.2 V/cell', '3.3 V/cell', '3.4 V/cell', '3.5 V/cell' ],
  pos=>[1,5],
},{
  name => 'Voltage Correction',
  type => 'OPTTYPE_UI', len => 7, ppos => 0, min => 0, max => 200, default => 0, steps => 1,
  size => 2,
  adr => 19,
  unit => '%',

},{
  name => 'Pitch P',
  type => 'OPTTYPE_SI', len => 5, ppos => 2, min => 0, max => 3000, default => 400, steps => 10,
  size => 2,
  adr => 0,
  pos=> [2,1],
},{
  name => 'Pitch I',
  type => 'OPTTYPE_UI', len => 7, ppos => 1, min => 0, max => 20000, default => 1000, steps => 50,
  size => 2,
  adr => 1,
},{
  name => 'Pitch D',
  type => 'OPTTYPE_UI', len => 3, ppos => 4, min => 0, max => 8000, default => 500, steps => 50,
  size => 2,
  adr => 2,
},{
  name => 'Pitch Motor Vmax',
  type => 'OPTTYPE_UI', len => 5, ppos => 0, min => 0, max => 255, default => 150, steps => 1,
  size => 2,
  adr => 3,

},{
  name => 'Roll P',
  type => 'OPTTYPE_SI', len => 5, ppos => 2, min => 0, max => 3000, default => 400, steps => 10,
  size => 2,
  adr => 6,
  pos=> [3,1],
},{
  name => 'Roll I',
  type => 'OPTTYPE_UI', len => 7, ppos => 1, min => 0, max => 20000, default => 1000, steps => 50,
  size => 2,
  adr => 7,
},{
  name => 'Roll D',
  type => 'OPTTYPE_UI', len => 3, ppos => 4, min => 0, max => 8000, default => 500, steps => 50,
  size => 2,
  adr => 8,
},{
  name => 'Roll Motor Vmax',
  type => 'OPTTYPE_UI', len => 5, ppos => 0, min => 0, max => 255, default => 150, steps => 1,
  size => 2,
  adr => 9,

},{
  name => 'Yaw P',
  type => 'OPTTYPE_SI', len => 5, ppos => 2, min => 0, max => 3000, default => 400, steps => 10,
  size => 2,
  adr => 12,
  pos=> [4,1],
},{
  name => 'Yaw I',
  type => 'OPTTYPE_UI', len => 7, ppos => 1, min => 0, max => 20000, default => 1000, steps => 50,
  size => 2,
  adr => 13,
},{
  name => 'Yaw D',
  type => 'OPTTYPE_UI', len => 3, ppos => 4, min => 0, max => 8000, default => 500, steps => 50,
  size => 2,
  adr => 14,
},{
  name => 'Yaw Motor Vmax',
  type => 'OPTTYPE_UI', len => 5, ppos => 0, min => 0, max => 255, default => 150, steps => 1,
  size => 2,
  adr => 15,


##--- PAN tab --------------------
},{
  name => 'Pan Mode Control',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => $FunctionInputMax, default => 0, steps => 1,
  size => 1,
  adr => 65,
  choices => \@FunctionInputChoicesList,
  expert=> 6,
  column=> 1,
},{
  name => 'Pan Mode Default Setting',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 4, default => 0, steps => 1,
  size => 1,
  adr => 66,
  choices => [ 'hold hold pan', 'hold hold hold', 'pan pan pan', 'pan hold hold', 'pan hold pan'],
  expert=> 6,
},{
  name => 'Pan Mode Setting #1',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 5, default => 1, steps => 1,
  size => 1,
  adr => 67,
  choices => [ 'hold hold pan', 'hold hold hold', 'pan pan pan', 'pan hold hold', 'pan hold pan', 'off' ],
  expert=> 6,
},{
  name => 'Pan Mode Setting #2',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 5, default => 4, steps => 1,
  size => 1,
  adr => 68,
  choices => [ 'hold hold pan', 'hold hold hold', 'pan pan pan', 'pan hold hold', 'pan hold pan', 'off'],
  expert=> 6,
},{
  name => 'Pan Mode Setting #3',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 5, default => 2, steps => 1,
  size => 1,
  adr => 69,
  choices => [ 'hold hold pan', 'hold hold hold', 'pan pan pan', 'pan hold hold', 'pan hold pan', 'off'],
  expert=> 6,

},{
  name => 'Pitch Pan (0 = hold)',
  type => 'OPTTYPE_UI', len => 5, ppos => 1, min => 0, max => 100, default => 20, steps => 1,
  size => 2,
  adr => 4,
  expert=> 6,
  column=> 2,
},{
  name => 'Pitch Pan Deadband',
  type => 'OPTTYPE_UI', len => 5, ppos => 1, min => 0, max => 100, default => 0, steps => 5,
  size => 2,
  adr => 5,
  expert=> 6,
  pos=> [2,3],
},{
  name => 'Pitch Pan Limiter',
  type => 'OPTTYPE_UI', len => 5, ppos => 0, min => 0, max => 100, default => 0, steps => 1,
  size => 2,
  adr => 102,
  unit=> '%',
  expert=> 6,

},{
  name => 'Roll Pan (0 = hold)',
  type => 'OPTTYPE_UI', len => 5, ppos => 1, min => 0, max => 100, default => 20, steps => 1,
  size => 2,
  adr => 10,
  expert=> 6,
  column=> 3,
},{
  name => 'Roll Pan Deadband',
  type => 'OPTTYPE_UI', len => 5, ppos => 1, min => 0, max => 100, default => 0, steps => 5,
  size => 2,
  adr => 11,
  expert=> 6,
  pos=> [3,3],
},{
  name => 'Roll Pan Limiter',
  type => 'OPTTYPE_UI', len => 5, ppos => 0, min => 0, max => 100, default => 0, steps => 1,
  size => 2,
  adr => 103,
  unit=> '%',
  expert=> 6,

},{
  name => 'Yaw Pan (0 = hold)',
  type => 'OPTTYPE_UI', len => 5, ppos => 1, min => 0, max => 100, default => 20, steps => 1,
  size => 2,
  adr => 16,
  expert=> 6,
  column=> 4,
},{
  name => 'Yaw Pan Deadband',
  type => 'OPTTYPE_UI', len => 5, ppos => 1, min => 0, max => 100, default => 0, steps => 5,
  size => 2,
  adr => 17,
  unit=> '�',
  expert=> 6,
  pos=> [4,3],
},{
  name => 'Yaw Pan Limiter',
  type => 'OPTTYPE_UI', len => 5, ppos => 0, min => 0, max => 100, default => 0, steps => 1,
  size => 2,
  adr => 104,
  unit=> '%',
  expert=> 6,


##--- RC INPUTS tab --------------------
},{
  name => 'Rc Dead Band',
  type => 'OPTTYPE_UI', len => 0, ppos => 0, min => 0, max => 50, default => 10, steps => 1,
  size => 2,
  adr => 43,
  unit => 'us',
  expert=> 3,
},{
  name => 'Rc Hysteresis',
  type => 'OPTTYPE_UI', len => 0, ppos => 0, min => 0, max => 20, default => 0, steps => 1,
  size => 2,
  adr => 105,
  unit => 'us',
  expert=> 3,

},{
  name => 'Rc Pitch Trim',
  type => 'OPTTYPE_SI', len => 0, ppos => 0, min => -100, max => 100, default => 0, steps => 1,
  size => 2,
  adr => 46,
  unit => 'us',
  expert=> 3,
  pos=>[1,4],
},{
  name => 'Rc Roll Trim',
  type => 'OPTTYPE_SI', len => 0, ppos => 0, min => -100, max => 100, default => 0, steps => 1,
  size => 2,
  adr => 53,
  unit => 'us',
  expert=> 3,
},{
  name => 'Rc Yaw Trim',
  type => 'OPTTYPE_SI', len => 0, ppos => 0, min => -100, max => 100, default => 0, steps => 1,
  size => 2,
  adr => 60,
  unit => 'us',
  expert=> 3,

},{
  name => 'Rc Pitch',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => $FunctionInputMax, default => 0, steps => 1,
  size => 1,
  adr => 44,
  choices => \@FunctionInputChoicesList,
  column => 2,
  expert=> 3,
},{
  name => 'Rc Pitch Mode',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 1, default => 0, steps => 1,
  size => 1,
  adr => 45,
  choices => [ 'absolute', 'relative'],
  expert=> 3,
},{
  name => 'Rc Pitch Min',
  type => 'OPTTYPE_SI', len => 0, ppos => 1, min => -1200, max => 1200, default => -250, steps => 5,
  size => 2,
  adr => 47,
  unit => '�',
  expert=> 3,
},{
  name => 'Rc Pitch Max',
  type => 'OPTTYPE_SI', len => 0, ppos => 1, min => -1200, max => 1200, default => 250, steps => 5,
  size => 2,
  adr => 48,
  unit => '�',
  expert=> 3,
},{
  name => 'Rc Pitch Speed Limit (0 = off)',
  type => 'OPTTYPE_UI', len => 0, ppos => 1, min => 0, max => 1000, default => 400, steps => 5,
  size => 2,
  adr => 49,
  unit => '�/s',
  expert=> 3,
},{
  name => 'Rc Pitch Accel Limit (0 = off)',
  type => 'OPTTYPE_UI', len => 0, ppos => 3, min => 0, max => 1000, default => 300, steps => 10,
  size => 2,
  adr => 50,
  expert=> 3,
},{
  name => 'Rc Pitch Offset',
  type => 'OPTTYPE_SI', len => 0, ppos => 1, min => -1200, max => 1200, default => 0, steps => 5,
  size => 2,
  adr => 106,
  unit => '�',
  expert=> 3,

},{
  name => 'Rc Roll',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => $FunctionInputMax, default => 0, steps => 1,
  size => 1,
  adr => 51,
  choices => \@FunctionInputChoicesList,
  column => 3,
  expert=> 3,
},{
  name => 'Rc Roll Mode',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 1, default => 0, steps => 1,
  size => 1,
  adr => 52,
  choices => [ 'absolute', 'relative'],
  expert=> 3,
},{
  name => 'Rc Roll Min',
  type => 'OPTTYPE_SI', len => 0, ppos => 1, min => -450, max => 450, default => -250, steps => 5,
  size => 2,
  adr => 54,
  unit => '�',
  expert=> 3,
},{
  name => 'Rc Roll Max',
  type => 'OPTTYPE_SI', len => 0, ppos => 1, min => -450, max => 450, default => 250, steps => 5,
  size => 2,
  adr => 55,
  unit => '�',
  expert=> 3,
},{
  name => 'Rc Roll Speed Limit (0 = off)',
  type => 'OPTTYPE_UI', len => 0, ppos => 1, min => 0, max => 1000, default => 400, steps => 5,
  size => 2,
  adr => 56,
  unit => '�/s',
  expert=> 3,
},{
  name => 'Rc Roll Accel Limit (0 = off)',
  type => 'OPTTYPE_UI', len => 0, ppos => 3, min => 0, max => 1000, default => 300, steps => 10,
  size => 2,
  adr => 57,
  expert=> 3,
},{
  name => 'Rc Roll Offset',
  type => 'OPTTYPE_SI', len => 0, ppos => 1, min => -1200, max => 1200, default => 0, steps => 5,
  size => 2,
  adr => 107,
  unit => '�',
  expert=> 3,

},{
  name => 'Rc Yaw',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => $FunctionInputMax, default => 0, steps => 1,
  size => 1,
  adr => 58,
  choices => \@FunctionInputChoicesList,
  column => 4,
  expert=> 3,
},{
  name => 'Rc Yaw Mode',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 2, default => 0, steps => 1,
  size => 1,
  adr => 59,
  choices => [ 'absolute', 'relative', 'relative turn around' ],
  expert=> 3,
},{
  name => 'Rc Yaw Min',
  type => 'OPTTYPE_SI', len => 0, ppos => 1, min => -2700, max => 2700, default => -250, steps => 10,
  size => 2,
  adr => 61,
  unit => '�',
  expert=> 3,
},{
  name => 'Rc Yaw Max',
  type => 'OPTTYPE_SI', len => 0, ppos => 1, min => -2700, max => 2700, default => 250, steps => 10,
  size => 2,
  adr => 62,
  unit => '�',
  expert=> 3,
},{
  name => 'Rc Yaw Speed Limit (0 = off)',
  type => 'OPTTYPE_UI', len => 0, ppos => 1, min => 0, max => 1000, default => 400, steps => 5,
  size => 2,
  adr => 63,
  unit => '�/s',
  expert=> 3,
},{
  name => 'Rc Yaw Accel Limit (0 = off)',
  type => 'OPTTYPE_UI', len => 0, ppos => 3, min => 0, max => 1000, default => 300, steps => 10,
  size => 2,
  adr => 64,
  expert=> 3,
},{
  name => 'Rc Yaw Offset',
  type => 'OPTTYPE_SI', len => 0, ppos => 1, min => -1200, max => 1200, default => 0, steps => 5,
  size => 2,
  adr => 108,
  unit => '�',
  expert=> 3,


##--- FUNCTIONS tab --------------------
},{
  name => 'Standby',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => $FunctionInputMax, default => 0, steps => 1,
  size => 1,
  adr => 70,
  choices => \@FunctionInputChoicesList,
  expert=> 4,
  column=> 1,

},{
  name => 'Re-center Camera',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => $FunctionInputMax, default => 0, steps => 1,
  size => 1,
  adr => 76,
  choices => \@FunctionInputChoicesList,
  expert=> 4,
  column=> 2,

#},{
#  name => 'PWM Passthrough',
#  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => $FunctionInputMax, default => 0, steps => 1,
#  size => 1,
#  adr => 77,
#  choices => \@FunctionInputChoicesList,
#  expert=> 4,
#  pos=>[2,5],

},{
  name => 'IR Camera Control',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => $FunctionInputMax, default => 0, steps => 1,
  size => 1,
  adr => 71,
  choices => \@FunctionInputChoicesList,
  expert=> 4,
  column=> 3,
},{
  name => 'Camera Model',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 1, default => 0, steps => 1,
  size => 1,
  adr => 72,
  choices => [ 'Sony Nex', 'Canon' ],
  expert=> 4,
},{
  name => 'IR Camera Setting #1',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 2, default => 0, steps => 1,
  size => 1,
  adr => 73,
  choices => [ 'shutter', 'shutter delay', 'video on/off' ],
  expert=> 4,
},{
  name => 'IR Camera Setting #2',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 3, default => 2, steps => 1,
  size => 1,
  adr => 74,
  choices => [ 'shutter', 'shutter delay', 'video on/off', 'off' ],
  expert=> 4,
},{
  name => 'Time Interval (0 = off)',
  type => 'OPTTYPE_UI', len => 0, ppos => 1, min => 0, max => 150, default => 0, steps => 1,
  size => 2,
  adr => 75,
  unit => 's',
  expert=> 4,


##--- GIMBAL SETUP tab --------------------
#},{
#  name => 'Saftey Configuration',
#  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 2, default => 0, steps => 1,
#  size => 1,
#  adr => 38,
#  choices => [ 'off', 'level 0', 'level 1', ],
#  expert=> 1,
#  pos=>[4,7],
},{
  name => 'Imu Orientation',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 23, default => 0, steps => 1,
  size => 1,
  adr => 39,
  choices => \@ImuChoicesList,
  expert=> 1,
  pos=>[1,1],
},{
  name => 'Imu2 Orientation',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 23, default => 0, steps => 1,
  size => 1,
  adr => 95,
  choices => \@ImuChoicesList,
  expert=> 1,
#  pos=>[1,3],
},{
  name => 'Imu2 Configuration',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 4, default => 0, steps => 1,
  size => 1,
  adr => 94,
  choices => [ 'off', 'gimbal support', 'gimbal support xy', 'yaw bracket', 'yaw bracket xy' ],
  expert=> 1,

},{
  name => 'Virtual Channel Configuration',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 5, default => 0, steps => 1,
  size => 1,
  adr => 41,
  choices => [ 'off',  'sum ppm 6', 'sum ppm 7', 'sum ppm 8', 'sum ppm 10', 'sum ppm 12' ],
  expert=> 1,
  pos=> [1,6],
},{
  name => 'Motor Configuration',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 1, default => 0, steps => 1,
  size => 1,
  adr => 40,
  choices => [ 'M0=pitch , M1=roll',  'M0=roll , M1=pitch', ],
  expert=> 1,
  pos=>[2,6],

#},{
#  name => 'Pitch FeedForward Gain (0=off)',
#  type => 'OPTTYPE_UI', len => 0, ppos => 2, min => 0, max => 200, default => 0, steps => 5,
#  size => 2,
#  adr => 96,
#  expert=> 1,
#  pos=>[2,6],
#},{
#  name => 'Roll FeedForward Gain (0=off)',
#  type => 'OPTTYPE_UI', len => 0, ppos => 2, min => 0, max => 200, default => 0, steps => 5,
#  size => 2,
#  adr => 97,
#  expert=> 1,
#  pos=>[3,6],
#},{
#  name => 'Yaw FeedForward Gain (0=off)',
#  type => 'OPTTYPE_UI', len => 0, ppos => 2, min => 0, max => 200, default => 0, steps => 5,
#  size => 2,
#  adr => 98,
#  expert=> 1,
#  pos=>[4,6],

#},{
#  name => 'Passthrough Configuration',
#  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 1, default => 0, steps => 1,
#  size => 1,
#  adr => 42,
#  choices => [ 'off', 'pwm 1520 us 55 Hz' ],
#  expert=> 4, #1,
#  pos=> [4,2], #[1,5],

},{
  name => 'Pitch Motor Poles',
  type => 'OPTTYPE_UI', len => 0, ppos => 0, min => 12, max => 28, default => 14, steps => 2,
  size => 2,
  adr => 20,
  expert=> 1,
  pos=> [2,1],
},{
  name => 'Pitch Motor Direction',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 2, default => 2, steps => 1,
  size => 1,
  adr => 21,
  choices => [ 'normal',  'reversed', 'auto' ],
  expert=> 1,
},{
  name => 'Pitch Offset',
  type => 'OPTTYPE_SI', len => 5, ppos => 2, min => -300, max => 300, default => 0, steps => 5,
  size => 2,
  adr => 22,
  unit=> '�',
  expert=> 1,
#  pos=> [2,3],
#},{
#  name => 'Pitch Limit Min (0 = off)',
#  type => 'OPTTYPE_SI', len => 5, ppos => 0, min => -160, max => 0, default => 0, steps => 1,
#  size => 2,
#  adr => 24,
#  unit=> '�',
#  expert=> 1,
#},{
#  name => 'Pitch Limit Max (0 = off)',
#  type => 'OPTTYPE_SI', len => 5, ppos => 0, min => 0, max => 160, default => 0, steps => 1,
#  size => 2,
#  adr => 25,
#  unit=> '�',
#  expert=> 1,
},{
  name => 'Pitch Startup Motor Pos',
  type => 'OPTTYPE_UI', len => 5, ppos => 0, min => 0, max => 1008, default => 504, steps => 1,
  size => 2,
  adr => 23,
  expert=> 1,

},{
  name => 'Roll Motor Poles',
  type => 'OPTTYPE_UI', len => 0, ppos => 0, min => 12, max => 28, default => 14, steps => 2,
  size => 2,
  adr => 26,
  expert=> 1,
  pos=> [3,1],
},{
  name => 'Roll Motor Direction',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 2, default => 2, steps => 1,
  size => 1,
  adr => 27,
  choices => [ 'normal',  'reversed', 'auto' ],
  expert=> 1,
},{
  name => 'Roll Offset',
  type => 'OPTTYPE_SI', len => 5, ppos => 2, min => -300, max => 300, default => 0, steps => 5,
  size => 2,
  adr => 28,
  unit=> '�',
  expert=> 1,
#  pos=> [3,4],
#},{
#  name => 'Roll Limit Min (0 = off)',
#  type => 'OPTTYPE_SI', len => 5, ppos => 0, min => -160, max => 0, default => 0, steps => 1,
#  size => 2,
#  adr => 30,
#  unit=> '�',
#  expert=> 1,
#},{
#  name => 'Roll Limit Max (0 = off)',
#  type => 'OPTTYPE_SI', len => 5, ppos => 0, min => 0, max => 160, default => 0, steps => 1,
#  size => 2,
#  adr => 31,
#  unit=> '�',
#  expert=> 1,
},{
  name => 'Roll Startup Motor Pos',
  type => 'OPTTYPE_UI', len => 5, ppos => 0, min => 0, max => 1008, default => 504, steps => 1,
  size => 2,
  adr => 29,
  expert=> 1,

},{
  name => 'Yaw Motor Poles',
  type => 'OPTTYPE_UI', len => 0, ppos => 0, min => 12, max => 28, default => 14, steps => 2,
  size => 2,
  adr => 32,
  expert=> 1,
  pos=> [4,1],
},{
  name => 'Yaw Motor Direction',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 2, default => 2, steps => 1,
  size => 1,
  adr => 33,
  choices => [ 'normal',  'reversed', 'auto', ],
  expert=> 1,
},{
  name => 'Yaw Offset',
  type => 'OPTTYPE_SI', len => 5, ppos => 2, min => -300, max => 300, default => 0, steps => 5,
  size => 2,
  adr => 34,
  unit=> '�',
  expert=> 1,
#  pos=> [4,4],
#},{
#  name => 'Yaw Limit Min (0 = off)',
#  type => 'OPTTYPE_SI', len => 5, ppos => 0, min => -160, max => 0, default => 0, steps => 1,
#  size => 2,
#  adr => 36,
#  unit=> '�',
#  expert=> 1,
#},{
#  name => 'Yaw Limit Max (0 = off)',
#  type => 'OPTTYPE_SI', len => 5, ppos => 0, min => 0, max => 160, default => 0, steps => 1,
#  size => 2,
#  adr => 37,
#  unit=> '�',
#  expert=> 1,
},{
  name => 'Yaw Startup Motor Pos',
  type => 'OPTTYPE_UI', len => 5, ppos => 0, min => 0, max => 1008, default => 504, steps => 1,
  size => 2,
  adr => 35,
  expert=> 1,


##--- EXPERT tab  --------------------
},{
  name => 'Acc LPF',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 6, default => 2, steps => 1,
  size => 1,
  adr => 85,
  choices => [ 'off', '1.5 ms', '4.5 ms', '12 ms', '25 ms', '50 ms', '100 ms' ],
  expert=> 2,
},{
  name => 'Imu DLPF',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 6, default => 0, steps => 1,
  size => 1,
  adr => 86,
  choices => [ '256 Hz', '188 Hz', '98 Hz', '42 Hz', '20 Hz', '10 Hz', '5 Hz'],
  expert=> 2,
},{
  name => 'Hold To Pan Transition Time',
  type => 'OPTTYPE_UI', len => 5, ppos => 0, min => 0, max => 1000, default => 250, steps => 25,
  size => 2,
  adr => 87,
  unit => 'ms',
  expert=> 2,
},{
  name => 'ADC Calibration',
  type => 'OPTTYPE_UI', len => 0, ppos => 0, min => 1000, max => 2000, default => 1550, steps => 10,
  size => 2,
  adr => 101,
  expert=> 2,
  pos=>[1,5],

},{
  name => 'Imu AHRS',
  type => 'OPTTYPE_UI', len => 5, ppos => 2, min => 0, max => 2500, default => 1000, steps => 100,
  size => 2,
  adr => 81,
  unit => 's',
  expert=> 2,
  column=> 2,
},{
  name => 'Imu Acc Threshold (0 = off)',
  type => 'OPTTYPE_UI', len => 5, ppos => 2, min => 0, max => 100, default => 25, steps => 1,
  size => 2,
  adr => 84,
  unit => 'g',
  expert=> 2,
},{
  name => 'Acc Noise Level',
  type => 'OPTTYPE_UI', len => 0, ppos => 3, min => 0, max => 150, default => 40, steps => 1,
  size => 2,
  adr => 89,
  unit => 'g',
  expert=> 2,
},{
  name => 'Acc Threshold (0 = off)',
  type => 'OPTTYPE_UI', len => 0, ppos => 2, min => 0, max => 100, default => 50, steps => 1,
  size => 2,
  adr => 90,
  unit => 'g',
  expert=> 2,
},{
  name => 'Acc Vertical Weight',
  type => 'OPTTYPE_UI', len => 0, ppos => 0, min => 0, max => 100, default => 25, steps => 5,
  size => 2,
  adr => 91,
  unit => '%',
  expert=> 2,
},{
  name => 'Acc Zentrifugal Correction',
  type => 'OPTTYPE_UI', len => 0, ppos => 0, min => 0, max => 100, default => 30, steps => 5,
  size => 2,
  adr => 92,
  unit => '%',
  expert=> 2,
},{
  name => 'Acc Recover Time',
  type => 'OPTTYPE_UI', len => 0, ppos => 0, min => 0, max => 1000, default => 250, steps => 5,
  size => 2,
  adr => 93,
  unit => ' ms',
  expert=> 2,


},{
  name => 'Acc Compensation Method',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 1, default => 1, steps => 1,
  size => 1,
  adr => 88,
  choices => [ 'standard', 'advanced'],
  expert=> 2,
  column=> 3,

},{
  name => 'Gyro LPF',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 6, default => 1, steps => 1,
  size => 1,
  adr => 100,
  choices => [ 'off', '1.5 ms', '3.0 ms', '4.5 ms', '6.0 ms', '7.5 ms', '9 ms' ],
  expert=> 2,

},{
  name => 'Imu2 FeedForward LPF',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 6, default => 1, steps => 1,
  size => 2,
  adr => 99,
  choices => [ 'off', '1.5 ms', '4 ms', '10 ms', '22 ms', '46 ms', '94 ms' ],
  expert=> 2,
#  pos=>[2,7],


},{
  name => 'Pitch Usage',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 3, default => 3, steps => 1,
  size => 1,
  adr => 78,
  choices => [ 'normal', 'level', 'startup pos', 'disabled'],
  expert=> 2,
  column=> 4,
},{
  name => 'Roll Usage',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 3, default => 3, steps => 1,
  size => 1,
  adr => 79,
  choices => [ 'normal', 'level', 'startup pos', 'disabled'],
  expert=> 2,
},{
  name => 'Yaw Usage',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 3, default => 3, steps => 1,
  size => 1,
  adr => 80,
  choices => [ 'normal', 'level', 'startup pos', 'disabled'],
  expert=> 2,

}
);

my $CMD_g_PARAMETER_ZAHL= 109; #102;

#my $CMD_d_PARAMETER_ZAHL #number of values transmitted with a 'd' get data command
my $CMD_d_PARAMETER_ZAHL= 31;

my %NameToOptionHash= (); #will be populated by PopulateOptions()

my $AccGravityConst = 16384;

#---------------------------
# Inifile
#---------------------------
my $IniFileName= $BGCStr."Tool.ini";
my $IniFile;
if( open(F,"<$IniFileName") ){
  close( F );
  $IniFile = new Config::IniFiles( -file => $IniFileName );
}
if( not defined $IniFile ){
  #$ErrorStr.= "Error in ".$IniFileName." or ini file not found\n";
}else{
  $IniFile->ReadConfig();
}

#---------------------------
# Font
#---------------------------
my $StdWinFontName= 'Tahoma';
my $StdWinFontSize= 8;
my $StdTextFontSize= 10;

if( defined $IniFile ){
  if( defined $IniFile->val('SYSTEM','FontName') ){ $StdWinFontName= $IniFile->val( 'SYSTEM','FontName'); }
  if( defined $IniFile->val('SYSTEM','FontSize') ){ $StdWinFontSize= $IniFile->val( 'SYSTEM','FontSize'); }
  if( defined $IniFile->val('SYSTEM','TextFontSize') ){ $StdTextFontSize= $IniFile->val( 'SYSTEM','TextFontSize'); }
}
my $StdWinFont= Win32::GUI::Font->new(-name=>$StdWinFontName, -size=>$StdWinFontSize, -bold => 0, );
my $StdWinFontBold= Win32::GUI::Font->new(-name=>$StdWinFontName, -size=>$StdWinFontSize, -bold => 0, );
my $StdTextFont= Win32::GUI::Font->new(-name=>'Lucida Console', -size=>$StdTextFontSize );



#---------------------------
# Dialog location
#---------------------------
my $DialogXPos= 100;
my $DialogYPos= 100;
if( defined $IniFile ){
  if( defined $IniFile->val('SYSTEM','XPos') ){ $DialogXPos= $IniFile->val( 'SYSTEM','XPos'); }
  if( defined $IniFile->val('SYSTEM','YPos') ){ $DialogYPos= $IniFile->val( 'SYSTEM','YPos'); }
}

my $DataDisplayXPos= 100;
my $DataDisplayYPos= 100;

if( defined $IniFile ){
  if( defined $IniFile->val('SYSTEM','DataDisplayXPos') ){ $DataDisplayXPos= $IniFile->val( 'SYSTEM','DataDisplayXPos'); }
  if( defined $IniFile->val('SYSTEM','DataDisplayYPos') ){ $DataDisplayYPos= $IniFile->val( 'SYSTEM','DataDisplayYPos'); }
}


#---------------------------
# Help texts
#---------------------------
my $HelpText= '';

my $HelpXPos= 150;
my $HelpYPos= 100;
my $HelpWidth= 500;
my $HelpHeight= 500;
if( defined $IniFile ){
  if( defined $IniFile->val('SYSTEM','HelpXPos') ){ $HelpXPos= $IniFile->val( 'SYSTEM','HelpXPos'); }
  if( defined $IniFile->val('SYSTEM','HelpYPos') ){ $HelpYPos= $IniFile->val( 'SYSTEM','HelpYPos'); }
  if( defined $IniFile->val('SYSTEM','HelpWidth') ){ $HelpWidth= $IniFile->val( 'SYSTEM','HelpWidth'); }
  if( defined $IniFile->val('SYSTEM','HelpHeight') ){ $HelpHeight= $IniFile->val( 'SYSTEM','HelpHeight'); }
}


#---------------------------
# Port & enumerate ports
#---------------------------
my $GetComPortOK= 0; #could also be local
my @PortList= ();
my $Port= '';

sub GetComPorts{
  my @ComList= ();
  #http://cpansearch.perl.org/src/CHORNY/Win32API-File-0.1200/ex/ListDevs.plx
  my $size= 4096; my $all;
  while( !QueryDosDevice([],$all,$size) ){ $size*= 2; }
  for( split(/\0/,$all) ){
    if(( QueryDosDevice($_,$all,0) )&&( $_ =~ /^COM/ )){
      push( @ComList, TrimStrToLength($_,10+4-length($_))."( ".ExtractComName($all)." )" );
    }
  }
  if( scalar @ComList==0 ){ push( @ComList, 'COM1' ); }
  return (scalar @ComList, sort{substr($a,3,3)<=>substr($b,3,3)} @ComList);
}

( $GetComPortOK, @PortList )= GetComPorts();
if( defined $IniFile ){
  if( defined $IniFile->val('PORT','Port') ){ $Port= $IniFile->val('PORT','Port'); } #$Port has only COMXX part
  #this adds the port specified in Ini file even if it is not present on system
  if( not grep{ExtractCom($_) eq ExtractCom($Port)} @PortList ){ push( @PortList, $Port ); }
}
if( $Port eq '' ){
  if( $GetComPortOK>0 ){ $Port= $PortList[0]; }
}else{
  if( $GetComPortOK>0 ){
    if( not grep{ExtractCom($_) eq $Port} @PortList ){
      if( scalar @PortList>1 ){ $Port= $PortList[1]; }else{ $Port= $PortList[0]; }
    }
  }else{
    $Port= '';
  }
}
#$Port has now COM part + friendly name

sub ExtractCom{
  my $s= shift;
  $s=~ s/^(COM\d{1,3}).*/$1/;
  return $s;
}

sub ExtractComName{
  my $s= shift;
  $s=~ s/.*\\(\w+)\x00*$/$1/;
  return $s;
}

sub ComIsUSB{
  my $s= uc(shift);
  $s=~ s/.*\\(\w+)\x00*$/$1/;
  if( $s =~ m/usb/i ){ return 1; }
  return 0;
}

sub ComIsBlueTooth{
  my $s= uc(shift);
  $s=~ s/.*\\(\w+)\x00*$/$1/;
  if( $s =~ m/bth/i ){ return 1; }
  return 0;
}

#---------------------------
# Baudrate
#---------------------------
my $Baudrate = 115200;

#---------------------------
# Timing
#---------------------------
my $ReadIntervalTimeout= 0xffffffff;
my $ReadTotalTimeoutMultiplier= 0;
my $ReadTotalTimeoutConstant= 0;

if( defined $IniFile ){
  if( defined $IniFile->val('TIMING','ReadIntervalTimeout') ){
    $ReadIntervalTimeout= StrToDez( $IniFile->val( 'TIMING','ReadIntervalTimeout') );
  }
  if( defined $IniFile->val('TIMING','ReadTotalTimeoutMultiplier') ){
    $ReadTotalTimeoutMultiplier= StrToDez( $IniFile->val( 'TIMING','ReadTotalTimeoutMultiplier') );
  }
  if( defined $IniFile->val('TIMING','ReadTotalTimeoutConstant') ){
    $ReadTotalTimeoutConstant= StrToDez( $IniFile->val( 'TIMING','ReadTotalTimeoutConstant') );
  }
}

my $ExecuteCmdTimeOut= 50; #100 ms
my $OpenPortDelay= 5; #seconds #<0 means just fixed time delay, as in older versions

if( defined $IniFile ){
  if( defined $IniFile->val('TIMING','ExecuteCmdTimeOut') ){ $ExecuteCmdTimeOut= $IniFile->val('TIMING','ExecuteCmdTimeOut'); }
  if( defined $IniFile->val('TIMING','OpenPortDelay') ){ $OpenPortDelay= $IniFile->val('TIMING','OpenPortDelay'); }
}


#---------------------------
# Options
#---------------------------
my @OptionList= ();
my $ColNumber= 4; #3;
my $RowNumber= 7; #7; #8;


sub ClearOptionList{
  @OptionList= (); undef @OptionList;
}

#is called in Read with parameters, in ClearOptions as SetOptionList()
sub SetOptionList{
  my $revison= uc(shift);
  #clear optionlist
  ClearOptionList();
  #DO HERE THE AVAILABLE OPTIONS!
  @OptionList= @OptionV005List;
  #check options for consistency and validity
  foreach my $Option (@OptionList){
    #check things
    if( not defined $Option->{size} ){ $ErrorStr.= "Error in options, size is missing\n"; next; }
    switch( $Option->{type} ){
      case ['OPTTYPE_LISTA','OPTTYPE_LISTB','OPTTYPE_UC','OPTTYPE_SC','OPTTYPE_UC+OPTTYPE_READONLY','OPTTYPE_SC+OPTTYPE_READONLY']{
        if( $Option->{size}!= 1 ){ $ErrorStr.= "Error in options, incompatible size\n"; }
      }
      case ['OPTTYPE_VER','OPTTYPE_UI','OPTTYPE_SI','OPTTYPE_UI+OPTTYPE_READONLY','OPTTYPE_SI+OPTTYPE_READONLY']{
        if( $Option->{size}!= 2 ){ $ErrorStr.= "Error in options, incompatible size\n"; }
      }
    }
    if(( $Option->{type} eq 'OPTTYPE_LISTA' )or( $Option->{type} eq 'OPTTYPE_LISTB' )){
      if( not defined $Option->{choices} ){ $ErrorStr.= "Error in options, no choices in list\n"; }
    }
    #MISSING: check that $Option->{modes}->{lc($s)} is existing and correct (no problem in write)
    #complete options
    if( not defined $Option->{steps} ){ $Option->{steps} = 1; }
    if( not defined $Option->{unit} ){ $Option->{unit} = ''; }
    if( not defined $Option->{default} ){
      if( index($Option->{type},'OPTTYPE_STR')>=0 ){
         $Option->{default} = '';
      }else{
        if( $Option->{min}>0 ){  $Option->{default} = $Option->{min}; }
        elsif( $Option->{max}<0 ){  $Option->{default} = $Option->{max}; }
        else{ $Option->{default} = 0; }
      }
    }
    if( not defined $Option->{expert} ){ $Option->{expert} = 0; }
    if( not defined $Option->{hidden} ){ $Option->{hidden} = 0; }
  }
}


#---------------------------
# Flash tab
#---------------------------
my $FirmwareHexFileDir= '';
my $STorM32BGCBoard= '';
my $FirmwareVersion= '';
my $STM32Programmer= '';
my $STLinkPath='ST\STLink';
my $STMFlashLoaderPath='ST\STMFlashLoader';
my $STMFlashLoaderExe='STMFlashLoaderOlliW.exe';


if( defined $IniFile ){
  if( defined $IniFile->val('FLASH','HexFileDir') ){ $FirmwareHexFileDir= RemoveBasePath($IniFile->val('FLASH','HexFileDir')); }
  if( defined $IniFile->val('FLASH','Board') ){ $STorM32BGCBoard= $IniFile->val('FLASH','Board'); }
  if( defined $IniFile->val('FLASH','Version') ){ $FirmwareVersion= $IniFile->val('FLASH','Version'); }
  if( defined $IniFile->val('FLASH','Programmer') ){ $STM32Programmer= $IniFile->val('FLASH','Programmer'); }
  if( defined $IniFile->val('FLASH','STLinkPath') ){ $STLinkPath= $IniFile->val('FLASH','STLinkPath'); }
  if( defined $IniFile->val('FLASH','STMFlashLoader') ){ $STMFlashLoaderPath= $IniFile->val('FLASH','STMFlashLoader'); }
}
if( not grep{$_->{name} eq $STorM32BGCBoard} @STorM32BGCBoardList ){ $STorM32BGCBoard= $STorM32BGCBoardList[0]->{name}; }
if( not grep{$_ eq $FirmwareVersion} @FirmwareVersionList ){ $FirmwareVersion= $FirmwareVersionList[0]; }
if( not grep{$_ eq $STM32Programmer} @STM32ProgrammerList ){ $STM32Programmer= $STM32ProgrammerList[0]; }


#---------------------------
# Toolsfile
#---------------------------
my @m_Tools_Menu= ();
my $w_Main;
sub AddNewTool{                 # AddNewTools( ">notepad", "tools_Notepad" );
  push( @m_Tools_Menu, shift ); #submenu of Tools menu
  push( @m_Tools_Menu, shift ); #command
}
sub ExecuteTool{ return $w_Main->ShellExecute('open',shift,shift,'',1); }
push( @m_Tools_Menu, 'Tools' );
push( @m_Tools_Menu, '' );
#AddNewTool( ">Motor Test Tool", "m_MotorTestTool" );
AddNewTool( ">Level Gimbal", "t_LevelGimbal" );
AddNewTool( ">-", 0 );
AddNewTool( ">Reset Controller", "t_ResetController" );
AddNewTool( ">-", 0 );
AddNewTool( ">Get Current Motor Directions", 't_GetCurrentMotorDirections' );
AddNewTool( ">Get Current Motor Positions", 't_GetCurrentMotorPositions' );
AddNewTool( ">Align Yaw Axis", 't_AlignYawAxis' );
AddNewTool( ">-", 0 );
AddNewTool( ">Erase EEPROM to 0xFF", 't_EraseEeprom' );
AddNewTool( ">-", 0 );
#AddNewTool( ">Share Settings", 'ShareSettings' );
#AddNewTool( ">-", 0 );

AddNewTool( ">BTConfigureTool - Configure Bluetooth Module", 't_BTConfigTool' );
AddNewTool( ">-", 0 );
AddNewTool( ">Mavlink Tool (experts only)", 't_MavlinkTool' );
#AddNewTool( ">Tuning Tool (experts only)", 't_TuningTool' );
#AddNewTool( ">-", 0 );

#my $TerminalFile= 'BrayTerminal.exe';
#if( defined $IniFile ){
#  if( defined $IniFile->val('SYSTEM','TerminalFile') ){ $TerminalFile= $IniFile->val('SYSTEM','TerminalFile'); }
#}
#if( open(F, $TerminalFile) ){
#  AddNewTool( ">Bray's Terminal", "tools_Terminal" );
#  sub tools_Terminal_Click{ ExecuteTool($TerminalFile,''); }
#}

#AddNewTool( ">-", 0 );
#AddNewTool( ">Calibrate Gyro", "CalibrateGyro" );
#AddNewTool( ">-", 0 );
#AddNewTool( ">Erase EEPROM to 0xFF", 'EraseEeprom' );



my $ToolsFile= '';
if( defined $IniFile ){
  if( defined $IniFile->val('SYSTEM','ToolsFile') ){ $ToolsFile= $IniFile->val('SYSTEM','ToolsFile'); }
}
if( open(F, $ToolsFile) ){
  my $s=''; while( <F> ){ chomp; $s.=$_."\n"; } close F;
  eval "$s"; if($@){ $ErrorStr.= "Error in tools file\n"; }
}

#---------------------------
# Global Variables
#---------------------------
my $p_Serial= ();

my $OptionsLoaded= 0; #somewhat unfortunate name, controls behavior before first read or load

my $OptionInvalidColor= 0xaaaaFF; #red
my $OptionValidColor= 0xbbFFbb; #green
my $OptionModifiedColor= 0xFFbbbb; #blue
if( defined $IniFile ){
  if( defined $IniFile->val('DIALOG','OptionInvalidColor') ){ $OptionInvalidColor= oct($IniFile->val('DIALOG','OptionInvalidColor')); }
  if( defined $IniFile->val('DIALOG','OptionValidColor') ){ $OptionValidColor= oct($IniFile->val('DIALOG','OptionValidColor')); }
  if( defined $IniFile->val('DIALOG','OptionModifiedColor') ){ $OptionModifiedColor= oct($IniFile->val('DIALOG','OptionModifiedColor')); }
}


if( $ErrorStr ne '' ){ ClearOptionList(); } #should however not be needed here.














#-----------------------------------------------------------------------------#
###############################################################################
###############################################################################
#
# Main Window
#
###############################################################################
###############################################################################
#-----------------------------------------------------------------------------#

my $MaxSetupTabs= 6; #this is the number of setup tabs
my $MaxConfigTabs= 3; #this is the number of config tabs
my @SetupTabList= ( 'setup', 'gimbalsetup', 'expert', 'rcinputs', 'functions', 'pan' ); #this is the name of the experts tabs

my $OPTIONSWIDTH_X= 180;
my $OPTIONSWIDTH_Y= 45;


my $xsize= $ColNumber*$OPTIONSWIDTH_X +40 -15 +20;
my $tabsize= $RowNumber*$OPTIONSWIDTH_Y + 40;
my $ysize= 245 + $tabsize -5;


my @m_Project_Menu= (
  '>Load from File...', 'm_OpenSettings',    #gets Filename, reads file, and extracts all settings
  '>Save to File...', 'm_SaveSettings',  #saves all settings into another .ini file
  '>Retrieve from EEPROM', 'm_RetrieveSettings',
  '>-', 0,
  '>Store to EEPROM', 'm_StoreSettings',
  '>-', 0,
  '>Default', 'm_DefaultSettings',
  '>-', 0,
  '>Clear GUI', 'm_Clear',
  '>-', 0,
  '>Share Settings', 'ShareSettings',
  '>-', 0,
  '>Exit', 'm_Exit',
);

my $m_Menubar= Win32::GUI::Menu-> new(
  'Setting' => '',
    @m_Project_Menu,
  @m_Tools_Menu,
  '?' => '',
#    '>Help on BLHeliTool...' => 'm_Help',
#    '>-', 0,
    '>About...' => 'm_About',
);

$w_Main= Win32::GUI::Window->new( -name=> 'm_Window', -font=> $StdWinFont,
  -text=> 'OlliW\'s '.$BGCStr.'Tool', -size=> [$xsize,$ysize], -pos=> [$DialogXPos,$DialogYPos],
  -menu=> $m_Menubar,
  -resizable=>0, -maximizebox=>0, -hasmaximize=>0,
);

$w_Main->SetIcon($Icon);

my $xpos= 10;
my $ypos= 15;

my %f_Tab= ();
$w_Main->AddTabFrame(-name=> 'w_Tab', -font=> $StdWinFontBold,
  -pos=> [$xpos,$ypos], -size=>[$xsize-22-4, $tabsize ],
  #-background=> [96,96,96],
  -onChange => sub{
    my $cur= $w_Main->w_Tab->SelectedItem();
    if( $cur<$MaxSetupTabs ){
      $w_Main->m_Read->Enable(); if($OptionsLoaded){ $w_Main->m_Write->Enable(); }
    }elsif( $cur<$MaxSetupTabs+$MaxConfigTabs ){ #this are the Configure tabs
      $w_Main->m_Read->Enable(); if($OptionsLoaded){ $w_Main->m_Write->Enable(); }
      SynchroniseConfigTabs();
    }else{
      $w_Main->m_Read->Disable(); $w_Main->m_Write->Disable();
    }
    w_Tab_Click(); 1; },
);
$w_Main->w_Tab->MinTabWidth(60);
$f_Tab{setup}= $w_Main->w_Tab->InsertItem(-text=> '     Main');
$f_Tab{pan}= $w_Main->w_Tab->InsertItem(-text=> '     Pan');
$f_Tab{rcinputs}= $w_Main->w_Tab->InsertItem(-text=> 'Rc Inputs');
$f_Tab{functions}= $w_Main->w_Tab->InsertItem(-text=> 'Functions');
$f_Tab{gimbalsetup}= $w_Main->w_Tab->InsertItem(-text=> 'Gimbal Setup' );
$f_Tab{expert}= $w_Main->w_Tab->InsertItem(-text=> '   Expert');
$f_Tab{configimu}= $w_Main->w_Tab->InsertItem(-text=> 'Configure IMU');
$f_Tab{configmotors}= $w_Main->w_Tab->InsertItem(-text=> 'Configure Motors');
$f_Tab{calibrateacc}= $w_Main->w_Tab->InsertItem(-text=> 'Calibrate Acc');
$f_Tab{flash}= $w_Main->w_Tab->InsertItem(-text=> 'Flash Firmware');

$ypos= $ysize-215+5;

$w_Main->AddLabel( -name=> 'm_Port_label', -font=> $StdWinFont,
  -text=> "Port", -pos=> [$xpos,$ypos],
);
$w_Main->AddCombobox( -name=> 'm_Port', -font=> $StdWinFont,
  -pos=> [$xpos+$w_Main->m_Port_label->Width()+3,$ypos-3], -size=> [70,180],
  -dropdown=> 1, -vscroll=>1,
  -onDropDown=> sub{
    ($GetComPortOK,@PortList)= GetComPorts();
    if($GetComPortOK>0){
      my $s= $_[0]->Text();
      $_[0]->Clear(); $_[0]->Add( @PortList ); $_[0]->SelectString( $s ); #$Port has COM + friendly name
      if($_[0]->SelectedItem()<0){ $_[0]->Select(0); }
    }
    1;
  }
);
$w_Main->m_Port->SetDroppedWidth(160);
$w_Main->m_Port->Add( @PortList );
if( scalar @PortList){ $w_Main->m_Port->SelectString( $Port ); } #$Port has COM + friendly name

$w_Main->AddButton( -name=> 'm_Status', -font=> $StdWinFont,
  -text=> 'Get Status', -pos=> [$xpos+130,$ypos-3], -width=> 80,
);

$w_Main->AddButton( -name=> 'm_DataDisplay', -font=> $StdWinFont,
  -text=> 'Data Display', -pos=> [$xpos+170+55,$ypos-3], -width=> 80,
);
#$w_Main->m_DataDisplay->Disable();

$w_Main->AddButton( -name=> 'm_Read', -font=> $StdWinFont,
  -text=> 'Read', -pos=> [$xpos+300+55,$ypos-3], -width=> 80,
);

$w_Main->AddButton( -name=> 'm_Write', -font=> $StdWinFont,
  -text=> 'Write', -pos=> [$xpos+420+55,$ypos-3], -width=> 80,
);
$w_Main->m_Write->Disable();


$w_Main->AddCheckbox( -name  => 'm_WriteAndStore_check', -font=> $StdWinFont,
  -pos=> [$xpos+420+55+100,$ypos+1], -size=> [12,12],
  -onClick=> sub{
      if( $_[0]->GetCheck() ){ $w_Main->m_Write->Text('Write+Store'); }else{ $w_Main->m_Write->Text('Write'); }
    }
);
$w_Main->m_WriteAndStore_check->Checked(0);

$w_Main->AddTextfield( -name=> 'm_RecieveText', -font=> $StdTextFont,
  -pos=> [5,$ysize-150-40+5], -size=> [$xsize-16,93+40-5],
  -vscroll=> 1, -multiline=> 1, -readonly => 1,
  -foreground =>[ 0, 0, 0],
  -background=> [192,192,192],#[96,96,96],
);





#-----------------------------------------------------------------------------#
###############################################################################
### do RC Inputs tab ###
###############################################################################
#-----------------------------------------------------------------------------#

$xpos= 20;
$ypos= 20;

$f_Tab{rcinputs}->AddButton( -name=> 'm_rc_AutoTrim', -font=> $StdWinFont,
  -text=> 'Auto Trim', -pos=> [$xpos+0*$OPTIONSWIDTH_X,$ypos+4+6*$OPTIONSWIDTH_Y], -width=> 120,
  -onClick=> sub{ ExecuteCalibrateRcTrim(); 1; },
);





#-----------------------------------------------------------------------------#
###############################################################################
### do Expert tab ###
###############################################################################
#-----------------------------------------------------------------------------#

$xpos= 20;
$ypos= 20;

$f_Tab{expert}->AddGroupbox( -name=> 'm_expert_Frame',
  -pos=> [10,-3], -size=> [520-175,333],
);

$f_Tab{expert}->AddLabel( -name=> 'm_expert_FrameText', -font=> $StdWinFont,
  -text=> 'Please ensure that you know what you\'re doing when tweaking these parameters :)',
  #-pos=> [385,200], -size=> [120,100], -wrap=>1,
  -pos=> [20,260], -size=> [135,68], -wrap=>1,
);


$f_Tab{expert}->AddButton( -name=> 'm_expert_EnableAllMotors', -font=> $StdWinFont,
  -text=> 'Enable all Motors', -pos=> [$xpos+3*$OPTIONSWIDTH_X,$ypos+4+4*$OPTIONSWIDTH_Y], -width=> 120,
  -onClick=> sub{ SetUsageOfAllMotors(0); 1; },
);

$f_Tab{expert}->AddButton( -name=> 'm_expert_DisableAllMotors', -font=> $StdWinFont,
  -text=> 'Disable all Motors', -pos=> [$xpos+3*$OPTIONSWIDTH_X,$ypos+4+5*$OPTIONSWIDTH_Y], -width=> 120,
  -onClick=> sub{ SetUsageOfAllMotors(3); 1; },
);





#-----------------------------------------------------------------------------#
###############################################################################
### do Flash tab ###
###############################################################################
#-----------------------------------------------------------------------------#

$xpos= 30;
$ypos= 20;

$f_Tab{flash}->AddLabel( -name=> 'm_flash_text1a', -font=> $StdWinFont,
  -text=> 'You can enter or browse the firmware file below, or select it via the following filters:', -pos=> [$xpos,$ypos],
);

$xpos= 30+20;
$ypos+= 25;
$f_Tab{flash}->AddLabel( -name=> 'm_flash_HexFileDir_label', -font=> $StdWinFont,
  -text=> "Firmware File Directory", -pos=> [$xpos,$ypos],
);
$f_Tab{flash}->AddTextfield( -name=> 'm_flash_HexFileDir', -font=> $StdWinFont,
  -pos=> [$xpos+120-1,$ypos-3], -size=> [$xsize-$xpos-80-120,23],
  -onChange=> sub{ SetFirmwareHexFile(); 1; }
);
$f_Tab{flash}->AddButton( -name=> 'm_flash_HexFileDir_button', -font=> $StdWinFont,
  -text=> '...', -pos=> [$xsize-100+20,$ypos-3], -width=> 18,
);
#$f_Tab{flash}->m_flash_HexFileDir->Text( $FirmwareHexFileDir ); #this must come later since it calls onChange

$ypos+= 30;
$f_Tab{flash}->AddLabel( -name=> 'm_flash_Board_label', -font=> $StdWinFont,
  -text=> 'STorM32 BGC board', -pos=> [$xpos,$ypos],
);
$f_Tab{flash}->AddCombobox( -name=> 'm_flash_Board', -font=> $StdWinFont,
  -pos=> [$xpos+120,$ypos-3], -size=> [260,200],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{ SetFirmwareHexFile(); 1; }
);
foreach my $board (@STorM32BGCBoardList){
  $f_Tab{flash}->m_flash_Board->Add( $board->{name} );
}
$f_Tab{flash}->m_flash_Board->SelectString( $STorM32BGCBoard );


$ypos+= 30;
$f_Tab{flash}->AddLabel( -name=> 'm_flash_Version_label', -font=> $StdWinFont,
  -text=> 'Firmware Version', -pos=> [$xpos,$ypos],
);
$f_Tab{flash}->AddCombobox( -name=> 'm_flash_Version', -font=> $StdWinFont,
  -pos=> [$xpos+120,$ypos-3], -size=> [260,200],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{ SetFirmwareHexFile(); 1; }
);
$f_Tab{flash}->m_flash_Version->Add( @FirmwareVersionList );
$f_Tab{flash}->m_flash_Version->SelectString( $FirmwareVersion );


$xpos= 30;
$ypos+= 50;
$f_Tab{flash}->AddLabel( -name=> 'm_flash_HexFile_label', -font=> $StdWinFont,
  -text=> "Firmware Hex File", -pos=> [$xpos,$ypos], -size=> [$xsize-100+20,20],
);
$f_Tab{flash}->AddTextfield( -name=> 'm_flash_HexFile', -font=> $StdWinFont,
  -pos=> [$xpos+140-1,$ypos+13-16], -size=> [$xsize-$xpos-80-140,23],
);
$f_Tab{flash}->AddButton( -name=> 'm_flash_HexFile_button', -font=> $StdWinFont,
  -text=> '...', -pos=> [$xsize-100+20,$ypos+13-13-3], -width=> 18,
);


$ypos+= 30;
$f_Tab{flash}->AddLabel( -name=> 'm_flash_STM32Programmer_label', -font=> $StdWinFont,
  -text=> 'STM32 Programmer', -pos=> [$xpos,$ypos],
);
$f_Tab{flash}->AddCombobox( -name=> 'm_flash_STM32Programmer', -font=> $StdWinFont,
  -pos=> [$xpos+140,$ypos-3], -size=> [260,200],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{ SetSTM32Programmer($_[0]->GetCurSel()); 1;}
);
$f_Tab{flash}->m_flash_STM32Programmer->Add( @STM32ProgrammerList );
$f_Tab{flash}->m_flash_STM32Programmer->SelectString( $STM32Programmer );


sub SetSTM32Programmer{
  my $i= shift;
  if( $i==$SystemBootloaderIndex ){
    $f_Tab{flash}->m_flash_STM32ProgrammerComPort_label->Show();
    $f_Tab{flash}->m_flash_STM32ProgrammerComPort->Show();
    $f_Tab{flash}->m_flash_STM32ProgrammerUsage_label->Show();
  }else{
    $f_Tab{flash}->m_flash_STM32ProgrammerComPort_label->Hide();
    $f_Tab{flash}->m_flash_STM32ProgrammerComPort->Hide();
    $f_Tab{flash}->m_flash_STM32ProgrammerUsage_label->Hide();
  }
  return 1;
}



$f_Tab{flash}->AddLabel( -name=> 'm_flash_STM32ProgrammerComPort_label', -font=> $StdWinFont,
  -text=> 'Com Port', -pos=> [$xpos+420,$ypos],
);
$f_Tab{flash}->AddCombobox( -name=> 'm_flash_STM32ProgrammerComPort', -font=> $StdWinFont,
  -pos=> [$xpos+420+$f_Tab{flash}->m_flash_STM32ProgrammerComPort_label->Width()+2,$ypos-3], -size=> [70,200],
  -dropdown=> 1, -vscroll=>1,
  -onDropDown=> sub{
    my ($STMComPortOK,@STMPortList)= GetComPorts();
    if($STMComPortOK>0){
      my $s= $_[0]->Text();
      $_[0]->Clear(); $_[0]->Add( @STMPortList ); $_[0]->SelectString( $s ); #$Port has COM + friendly name
      if($_[0]->SelectedItem()<0){ $_[0]->Select(0); }
    }
    1;
  }
);
$f_Tab{flash}->m_flash_STM32ProgrammerComPort->SetDroppedWidth(160);
$f_Tab{flash}->AddLabel( -name=> 'm_flash_STM32ProgrammerUsage_label', -font=> $StdWinFont,
  -pos=> [$xpos+430,$ypos+30], -multiline => 1, -height=>6*13+50, -width=>300,
  -text=> 'Usage:
1. Select com port of the adapter connected to UART1
2. Press RESET and BOOT0 buttons on the board
3. Release RESET while holding down BOOT0
4. Release BOOT0
5. Hit Flash Firmware',
);

$f_Tab{flash}->m_flash_STM32ProgrammerComPort_label->Hide();
$f_Tab{flash}->m_flash_STM32ProgrammerComPort->Hide();
$f_Tab{flash}->m_flash_STM32ProgrammerUsage_label->Hide();



$ypos+= 30;
$f_Tab{flash}->AddLabel( -name=> 'm_flash_FullErase_label', -font=> $StdWinFont,
  -text=> 'Perform full chip erase', -pos=> [$xpos,$ypos],
);
$f_Tab{flash}->AddCheckbox( -name  => 'm_flash_FullErase_check', -font=> $StdWinFont,
  -pos=> [$xpos+140,$ypos+1], -size=> [12,12],
);
$f_Tab{flash}->m_flash_FullErase_check->Checked(0);


$ypos+= 30;
$f_Tab{flash}->AddLabel( -name=> 'm_flash_Verify_label', -font=> $StdWinFont,
  -text=> 'Verify flashed firmware', -pos=> [$xpos,$ypos],
);
$f_Tab{flash}->AddCheckbox( -name  => 'm_flash_Verify_check', -font=> $StdWinFont,
  -pos=> [$xpos+140,$ypos+1], -size=> [12,12],
);
$f_Tab{flash}->m_flash_Verify_check->Checked(1);

$xpos= $xsize-80;
$ypos+= 30+10;
$f_Tab{flash}->AddButton( -name=> 'm_Flash', -font=> $StdWinFont,
  -text=> 'Flash Firmware', -pos=> [$xpos/2-60,$ypos-3], -width=> 120, -height=> 30,
);


sub SetFirmwareHexFile{
  my $s= $f_Tab{flash}->m_flash_HexFileDir->Text();
  if( $s ne '' ){ $s.= '\\'; }
  $s.= 'o323bgc_';
  my $board='';
  my $i= $f_Tab{flash}->m_flash_Board->GetCurSel();
  if( $i>=0 ){ $board= $STorM32BGCBoardList[$i]->{hexfile}; }
  my $version='';
  $i= $f_Tab{flash}->m_flash_Version->GetCurSel();
  if( $i>=0 ){ $version= $FirmwareVersionList[$i]; }
  $version=~ s/\.//g;
  $f_Tab{flash}->m_flash_HexFile->Text( $s.$version.'_'.$board.'.hex' );
}

$f_Tab{flash}->m_flash_HexFileDir->Text( $FirmwareHexFileDir );
SetFirmwareHexFile();
SetSTM32Programmer( $f_Tab{flash}->m_flash_STM32Programmer->GetCurSel() );






#-----------------------------------------------------------------------------#
###############################################################################
### do Configure IMU tab ###
###############################################################################
#-----------------------------------------------------------------------------#
sub SetUsageOfAllMotors{
  if( $OptionsLoaded<1 ){
    TextOut("\r\nPlease do first a read to get controller settings!\r\n");
    return 1;
  }
  my $usage= shift;
  my $Option= $NameToOptionHash{'Pitch Usage'};
  if( defined $Option ){
    SetOptionField( $Option, $usage );
    $Option->{textfield}->Change( -background => $OptionInvalidColor );
  }
  $Option= $NameToOptionHash{'Roll Usage'};
  if( defined $Option ){
    SetOptionField( $Option, $usage );
    $Option->{textfield}->Change( -background => $OptionInvalidColor );
  }
  $Option= $NameToOptionHash{'Yaw Usage'};
  if( defined $Option ){
    SetOptionField( $Option, $usage );
    $Option->{textfield}->Change( -background => $OptionInvalidColor );
  }
  if( $usage==3 ){ TextOut("\r\nDisable all motors... OK"); }
  elsif( $usage==2 ){ TextOut("\r\nSet all motors to startup pos... OK"); }
  elsif( $usage==1 ){ TextOut("\r\nSet all motors to level.. OK"); }
  else{ TextOut("\r\nEnable all motors... OK"); }
  ExecuteWrite(0);
  1;
}


my @ImuZList=( 'up', 'down', 'forward', 'backward', 'right', 'left' );
my @ImuXList=( 'forward', 'backward', 'right', 'left'  );

$xpos= 30;
$ypos= 20;

$f_Tab{configimu}->AddLabel( -name=> 'imuc_IntroText_label', -font=> $StdWinFont,
#  -text=> "1. Disconnect Motors
#For saftey, disconnect first motors from the BGC board and then power up the board.
#If not, then at least disable all motors (sets Usage options to 'disabled' and writes).",
  -text=> "1. Deactivate Motors
For saftey, power up board with USB only (no battery connected). Motors are then deactivated.",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>3*13+10,
);

#$f_Tab{configimu}->AddButton( -name=> 'imuc_DisableAllMotors', -font=> $StdWinFont,
#  -text=> 'Disable all Motors', -pos=> [$xpos+490-10,$ypos-3+26], -width=> 120+20,
#  -onClick=> sub{ SetUsageOfAllMotors(3); 1; },
#);

#$ypos+= 35 + 2*13;
$ypos+= 35 + 1*13;
$f_Tab{configimu}->AddLabel( -name=> 'imuc_ImuOrientation_label', -font=> $StdWinFont,
  -text=> '2. Configure Imu Orientation
Choose the imu. Then set first the direction of the imu\'s z axis, and then that of its x axis.',
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>30+15, -width=> 470,
);
$ypos+= 30 + 1*13;
$xpos= 50;
$f_Tab{configimu}->AddLabel( -name=> 'imuc_ImuNummer_label', -font=> $StdWinFont,
  -text=> ' selected imu', -pos=> [$xpos-1,$ypos],
);
$f_Tab{configimu}->AddCombobox( -name=> 'imuc_ImuNumber', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos+20-3], -size=> [120,160],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{
    my $Option; my $imux;
    if( $f_Tab{configimu}->imuc_ImuNumber->GetCurSel() == 1 ){
      $Option= $NameToOptionHash{'Imu2 Orientation'}; $imux= '2';
      $f_Tab{configimu}->imuc_ImuOrientationText2_label_IMU1->Hide();
      $f_Tab{configimu}->imuc_ImuOrientationText2_label_IMU2->Show();
    }else{
      $Option= $NameToOptionHash{'Imu Orientation'}; $imux= '';
      $f_Tab{configimu}->imuc_ImuOrientationText2_label_IMU2->Hide();
      $f_Tab{configimu}->imuc_ImuOrientationText2_label_IMU1->Show();
    }
    if( defined $Option ){
      my $no= GetOptionField( $Option );
      my $s= $ImuOrientationList[$no]->{axes};
      my $z= ConvertImuOrientation( $s, 'z' );
      my $x= ConvertImuOrientation( $s, 'x' );
      $f_Tab{configimu}->imuc_AxisZ->SelectString( $z );
      UpdateAxisXField( $z, $x );
      $f_Tab{configimu}->imuc_AxisX->SelectString( $x );
      PaintImuOrientation( $imux, $z, $x );
    }
    1;
  },
);
$f_Tab{configimu}->imuc_ImuNumber->SetDroppedWidth(100);
$f_Tab{configimu}->imuc_ImuNumber->Add( 'Imu  (camera IMU)' );
$f_Tab{configimu}->imuc_ImuNumber->Add( 'Imu2 (2nd IMU)' );
$f_Tab{configimu}->imuc_ImuNumber->Select( 0 );

$xpos= 120 + 50 + 50;
$f_Tab{configimu}->AddLabel( -name=> 'imuc_AxisZ_label', -font=> $StdWinFont,
  -text=> ' z axis points', -pos=> [$xpos-1,$ypos],
);
$f_Tab{configimu}->AddCombobox( -name=> 'imuc_AxisZ', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos+20-3], -size=> [80,160],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{
###    my $Option= $NameToOptionHash{'Imu Orientation'};
    my $Option; my $imux= '';
    if( $f_Tab{configimu}->imuc_ImuNumber->GetCurSel() == 1 ){
      $Option= $NameToOptionHash{'Imu2 Orientation'}; $imux= '2';
    }else{
      $Option= $NameToOptionHash{'Imu Orientation'}; $imux= '';
    }
    my $z= $_[0]->GetString($_[0]->GetCurSel());
    my $x= $f_Tab{configimu}->imuc_AxisX->Text();
    UpdateAxisXField( $z, $x );
    $x= $f_Tab{configimu}->imuc_AxisX->GetString( $f_Tab{configimu}->imuc_AxisX->GetCurSel() );
    my ($no)= PaintImuOrientation( $imux, $z, $x );
    if( defined $Option ){
      SetOptionField( $Option, $no );
      $Option->{textfield}->Change( -background => $OptionInvalidColor );
    }
    1;
  }
);
$f_Tab{configimu}->imuc_AxisZ->SetDroppedWidth(60);
$f_Tab{configimu}->imuc_AxisZ->Add( @ImuZList );
$f_Tab{configimu}->imuc_AxisZ->Select( 0 );
#$ypos+= 50;
$xpos+=120;
$f_Tab{configimu}->AddLabel( -name=> 'imuc_AxisX_label', -font=> $StdWinFont,
  -text=> ' x axis points', -pos=> [$xpos-1,$ypos],
);
$f_Tab{configimu}->AddCombobox( -name=> 'imuc_AxisX', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos+20-3], -size=> [80,160],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{
###    my $Option= $NameToOptionHash{'Imu Orientation'};
    my $Option; my $imux= '';
    if( $f_Tab{configimu}->imuc_ImuNumber->GetCurSel() == 1 ){
      $Option= $NameToOptionHash{'Imu2 Orientation'}; $imux= '2';
    }else{
      $Option= $NameToOptionHash{'Imu Orientation'}; $imux= '';
    }
    my $z= $f_Tab{configimu}->imuc_AxisZ->Text();
    my $x= $_[0]->GetString( $_[0]->GetCurSel() );
    my ($no)= PaintImuOrientation( $imux, $z, $x );
    if( defined $Option ){
      SetOptionField( $Option, $no );
      $Option->{textfield}->Change( -background => $OptionInvalidColor ); #$OptionModifiedColor );
    }
    1;
  }
);
$f_Tab{configimu}->imuc_AxisX->SetDroppedWidth(60);
$f_Tab{configimu}->imuc_AxisX->Add( @ImuXList );
$f_Tab{configimu}->imuc_AxisX->Select( 0 );
$xpos= 480 - 8 +50;
$ypos+= 5;
$xpos+=110;
$f_Tab{configimu}->AddLabel( -name=> 'imuc_ImuX_label', -font=> $StdWinFont,
  -text=> ' ', -pos=> [$xpos,$ypos-40+10], -width=> 70,
);
$f_Tab{configimu}->AddLabel( -name=> 'imuc_No_label', -font=> $StdWinFont,
  -text=> ' ', -pos=> [$xpos,$ypos-40+25], -width=> 70,
);
$f_Tab{configimu}->AddLabel( -name=> 'imuc_Name_label', -font=> $StdWinFont,
  -text=> ' ', -pos=> [$xpos,$ypos-40+40], -width=> 70,
);
$f_Tab{configimu}->AddLabel( -name=> 'imuc_Axes_label', -font=> $StdWinFont,
  -text=> ' ', -pos=> [$xpos,$ypos-40+55], -width=> 70,
);
$f_Tab{configimu}->AddLabel( -name=> 'imuc_Value_label', -font=> $StdWinFont,
  -text=> ' ', -pos=> [$xpos,$ypos-40+70], -width=> 70,
);
$xpos= 30;
$ypos+= 55;
$f_Tab{configimu}->AddLabel( -name=> 'imuc_ImuOrientationText2_label_IMU1', -font=> $StdWinFont,
  -text=> 'Check setting by running the Data Display: Tilting the CAMERA downwards must lead '.
'to positive Pitch angles, and rolling it like in flying a right turn to positive Roll angles.',
  -pos=> [$xpos,$ypos], -multiline => 1, -height=>26+13+10, -width=>450,
);
$f_Tab{configimu}->AddLabel( -name=> 'imuc_ImuOrientationText2_label_IMU2', -font=> $StdWinFont,
  -text=> 'Check setting by running the Data Display: Tilting the GIMBAL downwards must lead '.
'to positive Pitch angles, and rolling it like in flying a right turn to positive Roll angles.',
  -pos=> [$xpos,$ypos], -multiline => 1, -height=>26+13, -width=>450,
);
$f_Tab{configimu}->imuc_ImuOrientationText2_label_IMU2->Hide();
$ypos+= 3*13;
$f_Tab{configimu}->AddLabel( -name=> 'imuc_ImuOrientationText2xx_label', -font=> $StdWinFont,
  -text=> "NOTE: You need to press 'Write' to activate the setting.",
  -pos=> [$xpos,$ypos], -multiline => 1, -height=>26+13, -width=>420,
);

$f_Tab{configimu}->AddButton( -name=> 'imuc_Write', -font=> $StdWinFont,
  -text=> 'Write', -pos=> [$xpos+490-10,$ypos-3], -width=> 120+20,
  -onClick => sub{ ExecuteWrite(0); 1; }
);
$f_Tab{configimu}->imuc_Write->Disable();


$ypos+= 35; #50;
$f_Tab{configimu}->AddLabel( -name=> 'imuc_StoreInEEprom_label', -font=> $StdWinFont,
  -text=> "3. Store Settings
To keep settings write and store them to EEPROM, otherwise they won't be permanent.",
  -pos=> [$xpos,$ypos], -multiline=>1, -size=>[470,70],
);
$f_Tab{configimu}->AddButton( -name=> 'imuc_StoreInEEprom', -font=> $StdWinFont,
  -text=> 'Write + Store to EEPROM', -pos=> [$xpos+490-10,$ypos-3+13], -width=> 120+20,
  -onClick => sub{ ExecuteWrite(1); 1; } #-onClick => sub{  ExecuteStoreToEeprom(); 1; }
);

#moved to here to handle overlap of plot with textfield
my $w_ImuPlot= $f_Tab{configimu}->AddGraphic( -parent=> $f_Tab{configimu}, -name=> 'imuc_Plot', -font=> $StdWinFont,
    -pos=> [522,129-30-13], -size=> [100,90],
    -interactive=> 1,
);


sub UpdateAxisXField{
  my $z= shift;
  my $x= shift;
  if(( $z eq 'up' )or( $z eq 'down' )){ @ImuXList= ( 'forward', 'backward', 'right', 'left' ); }
  if(( $z eq 'forward' )or( $z eq 'backward' )){ @ImuXList= ( 'up', 'down', 'right', 'left' ); }
  if(( $z eq 'right' )or( $z eq 'left' )){ @ImuXList= ( 'up', 'down', 'forward', 'backward' ); }
  $f_Tab{configimu}->imuc_AxisX->Clear();
  $f_Tab{configimu}->imuc_AxisX->Add( @ImuXList );
  $f_Tab{configimu}->imuc_AxisX->SelectString( $x );
  if( $f_Tab{configimu}->imuc_AxisX->GetCurSel() < 0 ){ $f_Tab{configimu}->imuc_AxisX->SetCurSel(0); }
}


sub ConvertImuOrientation{
  my $s= shift; my $f= shift;
  my $i= index( $s, '+'.$f );
  if( $i==0 ){ return 'forward'; }elsif( $i==3 ){ return 'left'; }elsif( $i==6 ){ return 'up'; }
  $i= index( $s, '-'.$f );
  if( $i==0 ){ return 'backward'; }elsif( $i==3 ){ return 'right'; }elsif( $i==6 ){ return 'down'; }
}

sub FindImuOrientation{
  my $z= shift; my $x= shift;
  my $y= ''; my @s= ('??','??','??');  my $s1= ''; my $s2= '';
  #put z at right position
  if( $z eq 'forward' ){ $s[0]= '+z'; }
  elsif( $z eq 'backward' ) { $s[0]= '-z'; }
  elsif( $z eq 'left' ){ $s[1]= '+z'; }
  elsif( $z eq 'right' ) { $s[1]= '-z'; }
  elsif( $z eq 'up' )   { $s[2]= '+z'; }
  elsif( $z eq 'down' ) { $s[2]= '-z'; }
  #put x at right position
  if( $x eq 'forward' ){ $s[0]= '+x'; }
  elsif( $x eq 'backward' ) { $s[0]= '-x'; }
  elsif( $x eq 'left' ){ $s[1]= '+x'; }
  elsif( $x eq 'right' ) { $s[1]= '-x'; }
  elsif( $x eq 'up' )   { $s[2]= '+x'; }
  elsif( $x eq 'down' ) { $s[2]= '-x'; }
  # y is missing
  if( $s[0] eq '??' ){ $s1.= '+y'; $s2.= '-y'; }else{ $s1.= $s[0]; $s2.= $s[0]; }
  if( $s[1] eq '??' ){ $s1.= ' +y'; $s2.= ' -y'; }else{ $s1.= ' '.$s[1]; $s2.= ' '.$s[1]; }
  if( $s[2] eq '??' ){ $s1.= ' +y'; $s2.= ' -y'; }else{ $s1.= ' '.$s[2]; $s2.= ' '.$s[2]; }
  #find matching orientation
  my $no= 0; my $option;
  foreach my $o (@ImuOrientationList){
    if(( $o->{axes} eq $s1 )or( $o->{axes} eq $s2 )){ $y= $o->{axes}; $option= $o; last; }
    $no++;
  }
  $y= ConvertImuOrientation( $y, 'y' );
  return ($y,$no,$option->{value},$option->{name},$option->{axes});
}

sub AxesRemovePlus{ my $axes= shift; $axes=~ s/\+/ /g; return $axes; }

my $penImu = new Win32::GUI::Pen( -color => [127,127,127], -width => 1); #black
my $brushImu = new Win32::GUI::Brush( [191,191,191] ); #lightgray
my $brushImuFrame = new Win32::GUI::Brush( [0,0,0] );  #white
my $penImuGrid= new Win32::GUI::Pen( -color=> [127,127,127], -width=> 1);
my $fontImu= Win32::GUI::Font->new(-name=>'Lucida Console',-size=>8);

my @ImuColors= ( [255,0,0], [0,255,0], [0,0,255], [128,128,128], [0,255,255], [255,0,255], [255,255,0], [0,0,0]);

my $AxisLen= 32;
my $AxisXLen= int( $AxisLen/1.41 );
my $ArrowGap= 6;
my $ArrowXGap= 5;
my $AxisXOffset= -8;
my $AxisYOffset= +4;

sub AxisCoordinate{
  my $a= shift;
  if( $a eq 'up' )       { return (0                      , $AxisLen-$ArrowGap     , 5,$AxisLen+2); }
  if( $a eq 'down' )     { return (0                      ,-($AxisLen-$ArrowGap)   , 5,-$AxisLen+7); }
  if( $a eq 'forward' )  { return ($AxisXLen-$ArrowXGap   ,$AxisXLen-$ArrowXGap    , $AxisXLen+2,$AxisXLen  ); }
  if( $a eq 'backward' ) { return (-($AxisXLen-$ArrowXGap),-($AxisXLen-$ArrowXGap) , -$AxisXLen-6,-$AxisXLen+12  ); }
  if( $a eq 'right' )    { return ($AxisLen-$ArrowGap     , 0                      , $AxisLen-4,+12); }
  if( $a eq 'left' )     { return (-($AxisLen-$ArrowGap)  , 0                      , -$AxisLen,+12); }
}

sub PaintImuOrientation{
  my $imux= shift;
  my $z= shift;
  my $x= shift;
  my ($y,$no,$value,$name,$axes)= FindImuOrientation( $z, $x );
  # do first orientation info
  $f_Tab{configimu}->imuc_ImuX_label->Text( 'Imu'.$imux.'  ' );
  $f_Tab{configimu}->imuc_No_label->Text( 'no. '.$no );
  $f_Tab{configimu}->imuc_Name_label->Text( $name );
  $f_Tab{configimu}->imuc_Axes_label->Text( AxesRemovePlus($axes) );
  $f_Tab{configimu}->imuc_Value_label->Text( '('.$value.')' );
  # setting of Ranges and Regions
  my $Plot= $w_ImuPlot;
  my $DC= $Plot->GetDC();
  my ( $W, $H )= ($Plot->GetClientRect())[2..3];
  my $plot_region= CreateRectRgn Win32::GUI::Region(0,0,$W,$H);
  # get the DC's
  my $DC2= $DC->CreateCompatibleDC();
  my $bit= $DC->CreateCompatibleBitmap( $W, $H );
  $DC2->SelectObject( $bit );
  # draw the Plot region things: background, labels, xy, plotframe
  $DC2->SelectClipRgn( $plot_region );
  $DC2->SelectObject( $brushImu );
  $DC2->PaintRgn( $plot_region );
  $DC2->SelectObject( $fontImu );
  $DC2->TextColor( [127,127,127] );
  $DC2->BackColor( [191,191,191] );
  # draw the Imu things: grid, labels
  $DC2->SelectObject( $penImu );
  $DC2->Line( $W/2+$AxisXOffset, $H/2+$AxisYOffset-$AxisLen, $W/2+$AxisXOffset, $H/2+$AxisYOffset+$AxisLen ); #z
  $DC2->Line( $W/2+$AxisXOffset+$AxisXLen, $H/2+$AxisYOffset-$AxisXLen, $W/2+$AxisXOffset-$AxisXLen, $H/2+$AxisYOffset+$AxisXLen ); #x
  $DC2->Line( $W/2+$AxisXOffset-$AxisLen, $H/2+$AxisYOffset, $W/2+$AxisXOffset+$AxisLen, $H/2+$AxisYOffset ); #y
  $DC2->TextOut( $W/2-15, -1, 'up' );
  $DC2->TextOut( $W-36, $H/2+11, 'right' );
  $DC2->TextOut( $W-31, 6, 'for' );$DC2->TextOut( $W-31, 15, 'ward' );
  # draw seleced axes
  my $pen = new Win32::GUI::Pen( -color => $ImuColors[0], -width => 3 );
  $DC2->SelectObject( $pen );
  my @c= AxisCoordinate( $z );
  $DC2->Line( $W/2+$AxisXOffset, $H/2+$AxisYOffset, $W/2+$AxisXOffset+$c[0], $H/2+$AxisYOffset-$c[1] );
  $DC2->TextColor( $ImuColors[0] );
  $DC2->TextOut( $W/2+$AxisXOffset+$c[2], $H/2+$AxisYOffset-$c[3], 'z' );
  $pen = new Win32::GUI::Pen( -color => $ImuColors[1], -width => 3 );
  $DC2->SelectObject( $pen );
  @c= AxisCoordinate( $x );
  $DC2->Line( $W/2+$AxisXOffset, $H/2+$AxisYOffset, $W/2+$AxisXOffset+$c[0], $H/2+$AxisYOffset-$c[1] );
  $DC2->TextColor( $ImuColors[1] );
  $DC2->TextOut( $W/2+$AxisXOffset+$c[2], $H/2+$AxisYOffset-$c[3], 'x' );
  $pen = new Win32::GUI::Pen( -color => $ImuColors[2], -width => 3 );
  $DC2->SelectObject( $pen );
  @c= AxisCoordinate( $y );
  $DC2->Line( $W/2+$AxisXOffset, $H/2+$AxisYOffset, $W/2+$AxisXOffset+$c[0], $H/2+$AxisYOffset-$c[1] );
  $DC2->TextColor( $ImuColors[2] );
  $DC2->TextOut( $W/2+$AxisXOffset+$c[2], $H/2+$AxisYOffset-$c[3], 'y' );
  # update the screen in one action, and clean up
  $DC->BitBlt(0,0,$W,$H,$DC2,0,0);
  $DC2->DeleteDC();
  $DC->Validate();
  return ($no,$value,$name,$axes);
}

sub imuc_Plot_Paint{
  my $imux= '';
  if( $f_Tab{configimu}->imuc_ImuNumber->GetCurSel() == 1 ){ $imux= '2'; }else{ $imux= ''; }
  PaintImuOrientation( $imux, $f_Tab{configimu}->imuc_AxisZ->Text(), $f_Tab{configimu}->imuc_AxisX->Text() );
  1;
}






#-----------------------------------------------------------------------------#
###############################################################################
### do Configure Motors tab ###
###############################################################################
#-----------------------------------------------------------------------------#
sub SetDirectionOfAllMotors{
  my $direction= shift;
  my $Option= $NameToOptionHash{'Pitch Motor Direction'};
  if( defined $Option ){
    SetOptionField( $Option, $direction );
    $Option->{textfield}->Change( -background => $OptionInvalidColor );
  }
  $Option= $NameToOptionHash{'Roll Motor Direction'};
  if( defined $Option ){
    SetOptionField( $Option, $direction );
    $Option->{textfield}->Change( -background => $OptionInvalidColor );
  }
  $Option= $NameToOptionHash{'Yaw Motor Direction'};
  if( defined $Option ){
    SetOptionField( $Option, $direction );
    $Option->{textfield}->Change( -background => $OptionInvalidColor );
  }
  if( $direction==2 ){ TextOut("\r\nSet all motors to auto direction... OK"); }
  elsif( $direction==1 ){ TextOut("\r\nSet all motors to reversed direction.. OK"); }
  else{ TextOut("\r\nSet all motors to normal direction... OK"); }
  TextOut("\r\n");
  1;
}


$xpos= 30;
$ypos= 20;

$f_Tab{configmotors}->AddLabel( -name=> 'mc_IntroText_label', -font=> $StdWinFont,
#  -text=> "1. Disconnect Motors
#For saftey, disconnect first motors from the BGC board and then power up the board.
#If not, then at least disable all motors (sets Usage options to 'disabled' and writes).",
  -text=> "1. Deactivate Motors
For saftey, power up board with USB only (no battery connected). Motors are then deactivated.",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>3*13+20,
);

#$f_Tab{configmotors}->AddButton( -name=> 'mc_DisableAllMotors', -font=> $StdWinFont,
#  -text=> 'Disable all Motors', -pos=> [$xpos+490-10,$ypos-3+26], -width=> 120+20,
#  -onClick=> sub{ SetUsageOfAllMotors(3); 1; },
#);

$ypos+= 35 + 1*13;
$f_Tab{configmotors}->AddLabel( -name=> 'mc_IntroTextdrgdg_label', -font=> $StdWinFont,
  -text=> "2. Configure Basic Motor Settings
Set which motor ports are connected to the pitch and roll motors, and set the number of motor poles for each motor.",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>2*13+10,
);

$ypos+= 30 + 1*13;
$xpos= 120-40;
$f_Tab{configmotors}->AddLabel( -name=> 'mc_MC_label', -font=> $StdWinFont,
  -text=> ' motor configuration', -pos=> [$xpos-1,$ypos],
);
$f_Tab{configmotors}->AddCombobox( -name=> 'mc_MotorConfiguration', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos+20-3], -size=> [200,100],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{
    my $config= $_[0]->GetCurSel();
    if( $config<0 ){ $config=0; }
    if( $config>1 ){ $config=1; }
    my $Option= $NameToOptionHash{'Motor Configuration'};
    if( defined $Option ){
      SetOptionField( $Option, $config );
      $Option->{textfield}->Change( -background => $OptionInvalidColor );
    }
    1;
  }
);
$f_Tab{configmotors}->mc_MotorConfiguration->SetDroppedWidth(60);
$f_Tab{configmotors}->mc_MotorConfiguration->Add( ('Motor 0 = Pitch , Motor 1 = Roll','Motor 0 = Roll , Motor 1 = Pitch',) );
$f_Tab{configmotors}->mc_MotorConfiguration->Select( 0 );

$xpos-= 120;
$f_Tab{configmotors}->AddLabel( -name=> 'mc_MP_label', -font=> $StdWinFont,
  -text=> ' motor poles', -pos=> [$xpos+380-1,$ypos],
);
$f_Tab{configmotors}->AddLabel( -name=> 'mc_MotorPolesPitch_label', -font=> $StdWinFont,
  -text=> "Pitch", -pos=> [$xpos+380,$ypos+20],
);
$f_Tab{configmotors}->AddCombobox( -name=> 'mc_MotorPolesPitch', -font=> $StdWinFont,
  -pos=> [$xpos+380+$f_Tab{configmotors}->mc_MotorPolesPitch_label->Width()+3,$ypos+20-3], -size=> [60,160],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{ UpdateMotorPolesField($_[0]); 1; }
);
$f_Tab{configmotors}->mc_MotorPolesPitch->SetDroppedWidth(60);
$f_Tab{configmotors}->mc_MotorPolesPitch->Add( ('12','14','16','18','20','22','24','26','28') );

$f_Tab{configmotors}->AddLabel( -name=> 'mc_MotorPolesRoll_label', -font=> $StdWinFont,
  -text=> "Roll", -pos=> [$xpos+480,$ypos+20],
);
$f_Tab{configmotors}->AddCombobox( -name=> 'mc_MotorPolesRoll', -font=> $StdWinFont,
  -pos=> [$xpos+480+$f_Tab{configmotors}->mc_MotorPolesRoll_label->Width()+3,$ypos+20-3], -size=> [60,160],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{ UpdateMotorPolesField($_[0]); 1; }
);
$f_Tab{configmotors}->mc_MotorPolesRoll->SetDroppedWidth(60);
$f_Tab{configmotors}->mc_MotorPolesRoll->Add( ('12','14','16','18','20','22','24','26','28') );

$f_Tab{configmotors}->AddLabel( -name=> 'mc_MotorPolesYaw_label', -font=> $StdWinFont,
  -text=> "Yaw", -pos=> [$xpos+580,$ypos+20],
);
$f_Tab{configmotors}->AddCombobox( -name=> 'mc_MotorPolesYaw', -font=> $StdWinFont,
  -pos=> [$xpos+580+$f_Tab{configmotors}->mc_MotorPolesYaw_label->Width()+3,$ypos+20-3], -size=> [60,160],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{ UpdateMotorPolesField($_[0]); 1; }
);
$f_Tab{configmotors}->mc_MotorPolesYaw->SetDroppedWidth(60);
$f_Tab{configmotors}->mc_MotorPolesYaw->Add( ('12','14','16','18','20','22','24','26','28') );
$xpos= 30;

$ypos+= 35 + 2*13   ;# -1;
$f_Tab{configmotors}->AddLabel( -name=> 'mc_MotorConfiguration76575_label', -font=> $StdWinFont,
  -text=> "3. Set Motor Direction Auto-Detection Mode
Set the motor directions to 'auto' for all motors.",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>3*13+10,
);

$f_Tab{configmotors}->AddButton( -name=> 'mc_AutoAllMotors', -font=> $StdWinFont,
  -text=> "Set 'auto' for all Motors", -pos=> [$xpos+490-10,$ypos-3+13], -width=> 120+20,
  -onClick=> sub{ SetDirectionOfAllMotors(2); 1; },
);

$ypos+= 35 + 1*13;
$f_Tab{configmotors}->AddLabel( -name=> 'mc_EnableAllMotors_label', -font=> $StdWinFont,
  -text=> "4. Enable Motors and Store Settings
Enable all motors (sets Usage options to 'normal' and writes to board).
To keep settings write and store them to EEPROM, otherwise they will be lost.",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>45,
);
$f_Tab{configmotors}->AddButton( -name=> 'mc_EnableAllMotors', -font=> $StdWinFont,
  -text=> 'Enable all Motors', -pos=> [$xpos+490-10,$ypos-3+13], -width=> 120+20,
  -onClick=> sub{ SetUsageOfAllMotors(0); 1; },
);
$f_Tab{configmotors}->AddButton( -name=> 'mc_StoreInEEprom', -font=> $StdWinFont,
  -text=> 'Write + Store to EEPROM', -pos=> [$xpos+490-10,$ypos-3+3*13-1], -width=> 120+20,
  -onClick => sub{ ExecuteWrite(1); 1; }, #-onClick => sub{  ExecuteStoreToEeprom(); 1; }  #  -onClick => sub{   ExecuteWrite(0); 1; }
);

$ypos+= 35 + 2*13;
$f_Tab{configmotors}->AddLabel( -name=> 'mc_Start_label', -font=> $StdWinFont,
#  -text=> "5. Power down board, connect motors, and power up board again.",
  -text=> "5. Power down board, and power up board again with a battery.",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>30,
);


sub UpdateMotorPolesField{
  my $mot= shift;
  my $config= 2*$mot->GetCurSel()+12;
  my $Option;
  if( $mot==$f_Tab{configmotors}->mc_MotorPolesPitch ){
    $Option= $NameToOptionHash{'Pitch Motor Poles'};
  }elsif( $mot==$f_Tab{configmotors}->mc_MotorPolesRoll ){
    $Option= $NameToOptionHash{'Roll Motor Poles'};
  }else{
    $Option= $NameToOptionHash{'Yaw Motor Poles'};
  }
  if( defined $Option ){
    SetOptionField( $Option, $config );
    $Option->{textfield}->Change( -background => $OptionInvalidColor ); #$OptionModifiedColor );
  }
  1;
}


sub UpdateMotorDirectionField{
  my $mot= shift;
  my $config= $mot->GetCurSel();
  my $Option;
  if( $mot==$f_Tab{configmotors}->mc_MotorDirectionPitch ){
    $Option= $NameToOptionHash{'Pitch Motor Direction'};
  }elsif( $mot==$f_Tab{configmotors}->mc_MotorDirectionRoll ){
    $Option= $NameToOptionHash{'Roll Motor Direction'};
  }else{
    $Option= $NameToOptionHash{'Yaw Motor Direction'};
  }
  if( defined $Option ){
    SetOptionField( $Option, $config );
    $Option->{textfield}->Change( -background => $OptionInvalidColor );
  }
  1;
}









#-----------------------------------------------------------------------------#
###############################################################################
### do Calibrate Acc tab ###
###############################################################################
#-----------------------------------------------------------------------------#

my $CalibrationDataRecordIsValid= 0;

# this hash stores the actually worked on calibration data record
my %CalibrationDataRecord= (
  imuname => '', #
  imutype => 'MPU6050',
  imusettings => 'MPU6050_ACCEL_FS_2,  MPU6050_GYRO_FS_1000, MPU6050_DLPF_BW_256, MPU6050_SR_0',
  axzero=> '',
  ayzero=> '',
  azzero=> '',
  axscale=> '',
  ayscale=> '',
  azscale=> '',
  calibrationmethod=> '',
  raw=> '',
);

sub ClearCalibrationDataRecord{
  $CalibrationDataRecord{imuname}= '';
  $CalibrationDataRecord{imutype}= 'MPU6050';
  $CalibrationDataRecord{imusettings}= 'MPU6050_ACCEL_FS_2,  MPU6050_GYRO_FS_1000, MPU6050_DLPF_BW_256, MPU6050_SR_0';
  $CalibrationDataRecord{axzero}= '';
  $CalibrationDataRecord{ayzero}= '';
  $CalibrationDataRecord{azzero}= '';
  $CalibrationDataRecord{axscale}= '';
  $CalibrationDataRecord{ayscale}= '';
  $CalibrationDataRecord{azscale}= '';
  $CalibrationDataRecord{calibrationtype}= '';
  $CalibrationDataRecord{raw}= '';
}




$xpos= 30;
$ypos= 20;

$f_Tab{calibrateacc}->AddLabel( -name=> 'cacc_IntroText_label', -font=> $StdWinFont,
  -text=> "1. Deactivate Motors
For saftey, power up board with USB only (no battery connected). Motors are then deactivated.",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>3*13+20,
);

$ypos+= 35 + 1*13;
$f_Tab{calibrateacc}->AddLabel( -name=> 'cacc_IntroTextdrgdg_label', -font=> $StdWinFont,
  -text=> "2. Accelerometer Calibration Data
Chose imu. Then run an accelerometer calibration, or load acc calibration data from file.",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>2*13+10,
);

$ypos+= 3*13;
$f_Tab{calibrateacc}->AddButton( -name=> 'caac_Run1PointCalibration', -font=> $StdWinFont,
  -text=> 'Run 1-Point Calibration', -pos=> [$xpos+20,$ypos-3+2*13], -width=> 120+20,
);
$f_Tab{calibrateacc}->AddButton( -name=> 'caac_Run6PointCalibration', -font=> $StdWinFont,
  -text=> 'Run 6-Point Calibration', -pos=> [$xpos+20,$ypos-3+4*13], -width=> 120+20,
);

$xpos= 280;
$ypos+=  10;
$f_Tab{calibrateacc}->AddLabel( -name=> 'cacc_ImuNummer_label', -font=> $StdWinFont,
  -text=> ' imu', -pos=> [$xpos-1-30,$ypos],
);
$f_Tab{calibrateacc}->AddCombobox( -name=> 'cacc_ImuNumber', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos-3], -size=> [120,160],
  -dropdown=> 1, -vscroll=>1,
#  -background=>[0,255,0], -foreground=> [255,255,0],
  -onChange=> sub{ AccCalibrateTabClearCalibration(); 1; },
);
$f_Tab{calibrateacc}->cacc_ImuNumber->SetDroppedWidth(100);
$f_Tab{calibrateacc}->cacc_ImuNumber->Add( 'Imu  (camera IMU)' );
$f_Tab{calibrateacc}->cacc_ImuNumber->Add( 'Imu2 (2nd IMU)' );
$f_Tab{calibrateacc}->cacc_ImuNumber->Select( 0 );


my $AccCalibDataColor = [255,255,255];
$xpos= 280;
$ypos+= 3*13;
$f_Tab{calibrateacc}->AddLabel( -name=> 'caac_Zero_label', -font=> $StdWinFont,
  -text=> 'Zero', -pos=> [$xpos-1-30,$ypos+1*13],
);
$f_Tab{calibrateacc}->AddLabel( -name=> 'caac_Scale_label', -font=> $StdWinFont,
  -text=> 'Scale', -pos=> [$xpos-1-30,$ypos+3*13],
);
$f_Tab{calibrateacc}->AddLabel( -name=> 'caac_AccX_label', -font=> $StdWinFont,
  -text=> ' ax', -pos=> [$xpos-1,$ypos-7],
);
$f_Tab{calibrateacc}->AddTextfield( -name=> 'caac_AccXZero', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos+1*13-4], -size=> [60,23],
####  -readonly=> 1, -background=>$AccCalibDataColor,
  -align=> "right",
);
$f_Tab{calibrateacc}->AddTextfield( -name=> 'caac_AccXScale', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos+3*13-4], -size=> [60,23],
####  -readonly=> 1, -background=>$AccCalibDataColor,
  -align=> "right",
);
$xpos+= 70;
$f_Tab{calibrateacc}->AddLabel( -name=> 'caac_AccY_label', -font=> $StdWinFont,
  -text=> ' ay', -pos=> [$xpos-1,$ypos-7],
);
$f_Tab{calibrateacc}->AddTextfield( -name=> 'caac_AccYZero', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos+1*13-4], -size=> [60,23],
####  -readonly=> 1, -background=>$AccCalibDataColor,
  -align=> "right",
);
$f_Tab{calibrateacc}->AddTextfield( -name=> 'caac_AccYScale', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos+3*13-4], -size=> [60,23],
####  -readonly=> 1, -background=>$AccCalibDataColor,
  -align=> "right",
);
$xpos+= 70;
$f_Tab{calibrateacc}->AddLabel( -name=> 'caac_AccZ_label', -font=> $StdWinFont,
  -text=> ' az', -pos=> [$xpos-1,$ypos-7],
);
$f_Tab{calibrateacc}->AddTextfield( -name=> 'caac_AccZZero', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos+1*13-4], -size=> [60,23],
####  -readonly=> 1, -background=>$AccCalibDataColor,
  -align=> "right",
);
$f_Tab{calibrateacc}->AddTextfield( -name=> 'caac_AccZScale', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos+3*13-4], -size=> [60,23],
####  -readonly=> 1, -background=>$AccCalibDataColor,
  -align=> "right",
);

$xpos= 530;
$ypos-= 4*13;
$f_Tab{calibrateacc}->AddButton( -name=> 'caac_LoadFromFile', -font=> $StdWinFont,
  -text=> 'Load from File', -pos=> [$xpos,$ypos-3+1*13], -width=> 100,
  -onClick => sub{ ExecuteLoadCalibrationData(); 1; }
);
$f_Tab{calibrateacc}->AddButton( -name=> 'caac_SaveToFile', -font=> $StdWinFont,
  -text=> 'Save to File', -pos=> [$xpos,$ypos-3+3*13], -width=> 100,
  -onClick => sub{ ExecuteSaveCalibrationData(); 1; }
);
$f_Tab{calibrateacc}->AddButton( -name=> 'caac_Reset', -font=> $StdWinFont,
  -text=> 'Reset to Default', -pos=> [$xpos,$ypos-3+5*13], -width=> 100,
  -onClick => sub{ AccCalibrateTabSetCalibration(0,0,0,$AccGravityConst,$AccGravityConst,$AccGravityConst); 1; }
);
$f_Tab{calibrateacc}->AddButton( -name=> 'caac_ReadFromBoard', -font=> $StdWinFont,
  -text=> 'Read from Board', -pos=> [$xpos,$ypos-3+7*13], -width=> 100,
  -onClick => sub{ my $ret=ExecuteReadCalibrationData(); if($ret==1){AccCalibrateTabEnable(1);} 1; }
);
$xpos= 30;
$ypos+= 13;

$ypos= 20 + 17*13 + 4;
$f_Tab{calibrateacc}->AddLabel( -name=> 'caac_StoreInEEprom_label', -font=> $StdWinFont,
  -text=> "3. Store Calibration Data
Store the calibration data to the EEPROM, otherwise it won't be neither active nor permanent.

ATTENTION: Be carefull not to store nonsense data!",
  -pos=> [$xpos,$ypos], -multiline=>1, -size=>[460,70],
);
$f_Tab{calibrateacc}->AddButton( -name=> 'caac_StoreInEEprom', -font=> $StdWinFont,
  -text=> 'Store Calibration', -pos=> [$xpos+490-10,$ypos-3+13], -width=> 120+20,
  -onClick => sub{ ExecuteStoreCalibrationData(); 1; }
);
$f_Tab{calibrateacc}->caac_StoreInEEprom->Disable();


sub AccCalibrateTabEnable{
  if(shift){
    $f_Tab{calibrateacc}->caac_StoreInEEprom->Enable();
  }else{
    $f_Tab{calibrateacc}->caac_StoreInEEprom->Disable();
  }
}

sub AccCalibrateTabCopyRecordToTab{
  $f_Tab{calibrateacc}->caac_AccXZero->Text( $CalibrationDataRecord{axzero} );
  $f_Tab{calibrateacc}->caac_AccYZero->Text( $CalibrationDataRecord{ayzero} );
  $f_Tab{calibrateacc}->caac_AccZZero->Text( $CalibrationDataRecord{azzero} );
  $f_Tab{calibrateacc}->caac_AccXScale->Text( $CalibrationDataRecord{axscale} );
  $f_Tab{calibrateacc}->caac_AccYScale->Text( $CalibrationDataRecord{ayscale} );
  $f_Tab{calibrateacc}->caac_AccZScale->Text( $CalibrationDataRecord{azscale} );
}

sub AccCalibrateTabCopyTabToRecord{
  $CalibrationDataRecord{axzero}= $f_Tab{calibrateacc}->caac_AccXZero->Text();
  $CalibrationDataRecord{ayzero}= $f_Tab{calibrateacc}->caac_AccYZero->Text();
  $CalibrationDataRecord{azzero}= $f_Tab{calibrateacc}->caac_AccZZero->Text();
  $CalibrationDataRecord{axscale}= $f_Tab{calibrateacc}->caac_AccXScale->Text();
  $CalibrationDataRecord{ayscale}= $f_Tab{calibrateacc}->caac_AccYScale->Text();
  $CalibrationDataRecord{azscale}= $f_Tab{calibrateacc}->caac_AccZScale->Text();
}

sub AccCalibrateTabSetCalibration{
  $CalibrationDataRecord{axzero}= shift;
  $CalibrationDataRecord{ayzero}= shift;
  $CalibrationDataRecord{azzero}= shift;
  $CalibrationDataRecord{axscale}= shift;
  $CalibrationDataRecord{ayscale}= shift;
  $CalibrationDataRecord{azscale}= shift;
  AccCalibrateTabCopyRecordToTab();
}

sub AccCalibrateTabGetCalibration{
  AccCalibrateTabCopyTabToRecord();
  return (
    $CalibrationDataRecord{axzero},
    $CalibrationDataRecord{ayzero},
    $CalibrationDataRecord{azzero},
    $CalibrationDataRecord{axscale},
    $CalibrationDataRecord{ayscale},
    $CalibrationDataRecord{azscale},
  );
}

sub AccCalibrateTabClearCalibration{
  ClearCalibrationDataRecord();
  AccCalibrateTabCopyRecordToTab();
}

sub ExecuteReadCalibrationData{
  #read all calibration data from board
  my ($ret,$s)= ExecuteCommandFullwoGet( 'Cr', 'Read calibration data', '', 18*2 );
  if( $ret==0 ){ return 0; }
  my @CrData = unpack( "v18", $s );
  for(my $n=0;$n<18;$n++){ if( $CrData[$n]>32768 ){ $CrData[$n]-=65536; } }
  #copy to record and into tab
  ClearCalibrationDataRecord(); #clear record
  if( $f_Tab{calibrateacc}->cacc_ImuNumber->GetCurSel()!=1 ){ #IMU1 selected
    AccCalibrateTabSetCalibration( #copies into record and tab
      $CrData[0], $CrData[1], $CrData[2],  $CrData[3], $CrData[4], $CrData[5]
    );
  }else{ #IMU2
    AccCalibrateTabSetCalibration( #copies into record and tab
      $CrData[9], $CrData[10], $CrData[11],  $CrData[12], $CrData[13], $CrData[14]
    );
  }
  return 1;
}


sub CheckIntegrityOfCalibrationDataInTab{
  my $error_flag= 0;
  my ( $axzero, $ayzero, $azzero, $axscale, $ayscale, $azscale ) =  AccCalibrateTabGetCalibration();
  if( not $axzero =~ m/^[+-]?\d*$/ ){ $error_flag= 1; }
  if( not $ayzero =~ m/^[+-]?\d*$/ ){ $error_flag= 1; }
  if( not $azzero =~ m/^[+-]?\d*$/ ){ $error_flag= 1; }
  if( not $axscale =~ m/^[+]?\d*$/ ){ $error_flag= 1; }
  if( not $ayscale =~ m/^[+]?\d*$/ ){ $error_flag= 1; }
  if( not $azscale =~ m/^[+]?\d*$/ ){ $error_flag= 1; }
  if( abs($axzero)>7000 ){ $error_flag= 2; }
  if( abs($ayzero)>7000 ){ $error_flag= 2; }
  if( abs($azzero)>7000 ){ $error_flag= 2; }
  if(( $axscale<15000 )or( $axscale>17500 )){ $error_flag= 3; }
  if(( $ayscale<15000 )or( $ayscale>17500 )){ $error_flag= 3; }
  if(( $azscale<15000 )or( $azscale>17500 )){ $error_flag= 3; }
  if( $error_flag ){
    $w_Main->MessageBox( "You have entered invalid calibration data!

The values have to be (signed) integers, the Zero values need
to be in the range of -7000 to +7000, and the Scale values in
the range of +15000 to +17500.", 'WARNING', 0x0010 ); # MB_ICONHAND
  }
  return $error_flag;
}


sub ExecuteStoreCalibrationData{
#the first entry tells 1:acc1, 2:gyro1, 3:acc2, 4:gyro2, 5:acc1&gyro1, 6:acc2&gyro2, 7: all, else: error
  #make first a sanity check of the parameters
  if( CheckIntegrityOfCalibrationDataInTab()>0 ){ return; }
  #warn that calibration will be overwritten
  if(
    $w_Main->MessageBox( "You are going to rewrite calibration data permanently!

Are you sure you want to continue?", 'WARNING', 0x0034 ) #MB_ICONEXCLAMATION|MB_YESNO
    != 6 #IDYES
  ){ return; }
  my @CalibrationDataArray=(); #this holds all data as array
  for(my $n=0; $n<18; $n++){ $CalibrationDataArray[$n]= 0; } #this is to create array with 18 fields
  my $CwData=''; # this holds the data as packed string
  if( $f_Tab{calibrateacc}->cacc_ImuNumber->GetCurSel()!=1 ){ #IMU1 selected
    ( $CalibrationDataArray[0], $CalibrationDataArray[1], $CalibrationDataArray[2],
      $CalibrationDataArray[3], $CalibrationDataArray[4], $CalibrationDataArray[5] ) =  AccCalibrateTabGetCalibration();
    $CwData = pack( "v", '1' ); #1: store only IMU1 acc values
  }else{ #IMU2
    ( $CalibrationDataArray[9], $CalibrationDataArray[10], $CalibrationDataArray[11],
      $CalibrationDataArray[12], $CalibrationDataArray[13], $CalibrationDataArray[14] ) =  AccCalibrateTabGetCalibration();
    $CwData = pack( "v", '3' ); #3: store only IMU2 acc values
  }
  for(my $n=0;$n<18;$n++){ $CwData .= pack( "v", $CalibrationDataArray[$n] ); }
  ExecuteCommandWritewoGet( 'Cw', 'Write calibration data', '', $CwData );
}

my $SettingsFile_lastdir= $ExePath; #also used below for save and load settings

sub ExecuteSaveCalibrationData{
  #make first a sanity check of the parameters
  if( CheckIntegrityOfCalibrationDataInTab()>0 ){ return; }
  my $file= Win32::GUI::GetSaveFileName( -owner=> $w_Main,
    -title=> 'Save Calibration Data to File',
    -nochangedir=> 1,
    -directory=> $SettingsFile_lastdir, #".\\",
    -defaultextension=> '.cal',
    -filter=> ['*.cal'=>'*.cal','All files' => '*.*'],
    -pathmustexist=> 1,
    -overwriteprompt=> 1,
    -noreadonlyreturn => 1,
    -explorer=>0,
  );
  if( $file ){
    if( !open(F,">$file") ){ $w_Main->MessageBox("Some error occured, sorry",'ERROR'); return; }
    print F 'IMUNAME: '.NameExtStr($file)."\n";
    print F 'IMUTYPE: '.$CalibrationDataRecord{imutype}."\n";
    print F 'IMUSETTINGS: '.$CalibrationDataRecord{imusettings}."\n";
    print F 'RECORD#1'."\n";
    print F 'AXZERO: '.$CalibrationDataRecord{axzero}."\n";
    print F 'AYZERO: '.$CalibrationDataRecord{ayzero}."\n";
    print F 'AZZERO: '.$CalibrationDataRecord{azzero}."\n";
    print F 'AXSCALE: '.$CalibrationDataRecord{axscale}."\n";
    print F 'AYSCALE: '.$CalibrationDataRecord{ayscale}."\n";
    print F 'AZSCALE: '.$CalibrationDataRecord{azscale}."\n";
    print F 'CALIBRATIONMETHOD: '.$CalibrationDataRecord{calibrationmethod}."\n";
    print F 'TEMPERATURE: '.$CalibrationDataRecord{temperature}."\n";
    print F 'RAW: '."\n";
    print F $CalibrationDataRecord{raw}."\n";
    close(F);
  }elsif( Win32::GUI::CommDlgExtendedError() ){$w_Main->MessageBox("Some error occured, sorry",'ERROR');}
  1;
}

sub ExecuteLoadCalibrationData{
  my $file= Win32::GUI::GetOpenFileName( -owner=> $w_Main,
    -title=> 'Load Calibration Data from File',
    -nochangedir=> 1,
    -directory=> $SettingsFile_lastdir, #".\\",
    -defaultextension=> '.cal',
    -filter=> ['*.cal'=>'*.cal','All files' => '*.*'],
    -pathmustexist=> 1,
    -filemustexist=> 1,
  );
  if( $file ){
    if( !open(F,"<$file") ){ $w_Main->MessageBox( "Some error occured, sorry",'ERROR'); return; }
    my $s=''; while(<F>){ $s.= $_.'\n'; } close(F);
    #$s =~ /IMUNAME\s*:\s*(.+?)\\n/;
    $s =~ /AXZERO\s*:\s*([+-]?\d+)\s*\\n/; my $axzero = $1;
    $s =~ /AYZERO\s*:\s*([+-]?\d+)\s*\\n/; my $ayzero = $1;
    $s =~ /AZZERO\s*:\s*([+-]?\d+)\s*\\n/; my $azzero = $1;
    $s =~ /AXSCALE\s*:\s*([+-]?\d+)\s*\\n/; my $axscale = $1;
    $s =~ /AYSCALE\s*:\s*([+-]?\d+)\s*\\n/; my $ayscale = $1;
    $s =~ /AZSCALE\s*:\s*([+-]?\d+)\s*\\n/; my $azscale = $1;
    AccCalibrateTabSetCalibration( $axzero, $ayzero, $azzero, $axscale, $ayscale, $azscale );
  }elsif( Win32::GUI::CommDlgExtendedError() ){ $w_Main->MessageBox("Some error occured, sorry",'ERROR'); }
  1;
}



#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#

#is called then main tab is changed
#is also called in DefaultSettings, RetrieveSettings, Clear, Read operations
sub SynchroniseConfigTabs{
  #synchronize Imu Orientation settings
###  my $Option= $NameToOptionHash{'Imu Orientation'};
  my $Option; my $imux= '';
  if( $f_Tab{configimu}->imuc_ImuNumber->GetCurSel() == 1 ){
    $Option= $NameToOptionHash{'Imu2 Orientation'}; $imux= '2';
    $f_Tab{configimu}->imuc_ImuOrientationText2_label_IMU1->Hide();
    $f_Tab{configimu}->imuc_ImuOrientationText2_label_IMU2->Show();
  }else{
    $Option= $NameToOptionHash{'Imu Orientation'}; $imux= '';
    $f_Tab{configimu}->imuc_ImuOrientationText2_label_IMU2->Hide();
    $f_Tab{configimu}->imuc_ImuOrientationText2_label_IMU1->Show();
  }
  if( defined $Option ){
    my $no= GetOptionField( $Option );
    my $s= $ImuOrientationList[$no]->{axes};
    my $z= ConvertImuOrientation( $s, 'z' );
    my $x= ConvertImuOrientation( $s, 'x' );
    $f_Tab{configimu}->imuc_AxisZ->SelectString( $z );
    UpdateAxisXField( $z, $x );
    $f_Tab{configimu}->imuc_AxisX->SelectString( $x );
    PaintImuOrientation( $imux, $z, $x );
  }
  #synchronize Motor Configuration setting
  $Option= $NameToOptionHash{'Motor Configuration'};
  if( defined $Option ){
    my $no= GetOptionField( $Option );
    $f_Tab{configmotors}->mc_MotorConfiguration->Select( $no );
  }
  #synchronize Motor Poles settings
  $Option= $NameToOptionHash{'Pitch Motor Poles'};
  if( defined $Option ){
    my $no= GetOptionField( $Option );
    $f_Tab{configmotors}->mc_MotorPolesPitch->SelectString( $no );
  }
  $Option= $NameToOptionHash{'Roll Motor Poles'};
  if( defined $Option ){
    my $no= GetOptionField( $Option );
    $f_Tab{configmotors}->mc_MotorPolesRoll->SelectString( $no );
  }
  $Option= $NameToOptionHash{'Yaw Motor Poles'};
  if( defined $Option ){
    my $no= GetOptionField( $Option );
    $f_Tab{configmotors}->mc_MotorPolesYaw->SelectString( $no );
  }
}












#-----------------------------------------------------------------------------#
###############################################################################
### do Basic and Advanced Setup tabs ###
###############################################################################
#-----------------------------------------------------------------------------#

sub CreateOptionField{
  my $tab_ptr= shift;
  my $xpos= shift;
  my $ypos= shift;
  my $nr= shift;
      my $label; my $textfield; my $setfield; my $info;
      my $DummyOption;
      #create label
      my %labelparams=( -name=> 'OptionField'.$nr.'_label', -font=> $StdWinFont,
        -text=> 'Field'.$nr, -pos=> [$xpos,$ypos-1], -size=> [145,15],
      );
      $label= $f_Tab{$tab_ptr}->AddLabel(%labelparams);
      $DummyOption->{label}= $label;
      #create readonly textfield
      my %textfieldparams=( -name=> 'OptionField'.$nr.'_readonly', -font=> $StdWinFont,
        -pos=> [$xpos,$ypos+13], -size=> [120,23],
        -readonly => 1, -align => 'center',  -background => $OptionInvalidColor,
      );
      $textfield= $f_Tab{$tab_ptr}->AddTextfield(%textfieldparams);
      $textfield->Hide();
      $DummyOption->{textfield_readonly}= $textfield;
      #create textfield
      %textfieldparams=( -name=> 'OptionField'.$nr.'_str', -font=> $StdWinFont,
        -pos=> [$xpos,$ypos+13], -size=> [120,23],
        -background => $OptionInvalidColor,
      );
      $textfield= $f_Tab{$tab_ptr}->AddTextfield(%textfieldparams);
      $textfield->Hide();
      $DummyOption->{textfield_str}= $textfield;
      #create textfield with up/down
      %textfieldparams=( -name=> 'OptionField'.$nr.'_updown', -font=> $StdWinFont,
        -pos=> [$xpos,$ypos+13], -size=> [120,23],
        -readonly => 1, -align => 'center', -background => $OptionInvalidColor,
      );
      $textfield=$f_Tab{$tab_ptr}->AddTextfield( %textfieldparams );
      $textfield->Hide();
      $DummyOption->{textfield_updown}= $textfield;
      my %setfieldparams=( -name=> 'OptionField'.$nr.'_updownfield', -font=> $StdWinFont,
        -pos=> [$xpos+120,$ypos+13], -size=> [100,23],
        -autobuddy => 0, -arrowkeys => 1,
        -onScroll => sub{
           onScrollSetTextfield( $DummyOption->{option} );
           if($OptionsLoaded){ $DummyOption->{textfield_updown}->Change( -background => $OptionModifiedColor ); }
           1;
         },
      );
      $setfield= $f_Tab{$tab_ptr}->AddUpDown(%setfieldparams);
      $setfield->Hide();
      $DummyOption->{updownfield}= $setfield;
      #create textfield with slider
      %textfieldparams= ( -name=> 'OptionField'.$nr.'_slider', -font=> $StdWinFont,
        -pos=> [$xpos,$ypos+13], -size=> [60,23],
        -readonly => 1, -align => 'center', -background => $OptionInvalidColor,
      );
      $textfield= $f_Tab{$tab_ptr}->AddTextfield(%textfieldparams);
      $textfield->Hide();
      $DummyOption->{textfield_slider}= $textfield;
      %setfieldparams= ( -name=> 'OptionField'.$nr.'_sliderfield', -font=> $StdWinFont,
        -pos=> [$xpos+60,$ypos+13], -size=> [90,23], #[100,23],
        -aligntop => 1, -autoticks => 0,
        -onScroll => sub{
           onScrollSetTextfield( $DummyOption->{option} );
           if($OptionsLoaded){ $DummyOption->{textfield_slider}->Change( -background => $OptionModifiedColor ); }
           1;
         },
      );
      $setfield= $f_Tab{$tab_ptr}->AddTrackbar(%setfieldparams);
      $setfield->Hide();
      $setfield->SetLineSize( 1 );
      $setfield->SetPageSize( 1 );
      $DummyOption->{sliderfield}= $setfield;
      #create info field (right of label)
      %labelparams=( -name=> 'OptionField'.$nr.'_infofield', -font=> $StdWinFont,
        -text=> '', -pos=> [$xpos+66,$ypos], -size=> [87,13], -align=> 'center', #-background => $OptionInvalidColor,
      );
      $label= $f_Tab{$tab_ptr}->AddLabel(%labelparams);
      $label->Hide();
      $DummyOption->{infofield}= $label;
  return $DummyOption;
}

my @DummyOptionList= ();

#create dummy option fields
for(my $ex=0; $ex<$MaxSetupTabs; $ex++){
  my $tab_ptr= $SetupTabList[$ex];
  for(my $i=0; $i<$ColNumber; $i++){
    for(my $j=0; $j<$RowNumber; $j++){
      $xpos= 20+($i)*$OPTIONSWIDTH_X; $ypos= 10 + ($j)*$OPTIONSWIDTH_Y;
      my $nr= $j + $i*$RowNumber;
      $DummyOptionList[$ex][$nr]->{nr}= $nr; #this is just to create it
#      my $DummyOption= $DummyOptionList[$ex][$nr];
      $DummyOptionList[$ex][$nr] = CreateOptionField( $tab_ptr, $xpos, $ypos, $nr );
    }
  }
}






$xpos= 30+(1)*$OPTIONSWIDTH_X;
$ypos= 10 + (6)*$OPTIONSWIDTH_Y;
my $PitchIMCf0_label= $f_Tab{setup}->AddLabel( -name=> 'PitchIMUf0_label', -font=> $StdWinFont,
  -text=> '  f0 =', -pos=> [$xpos,$ypos], -size=> [150,13+2],
);
my $PitchIMCd_label= $f_Tab{setup}->AddLabel( -name=> 'PitchIMUd_label', -font=> $StdWinFont,
  -text=> '   d =', -pos=> [$xpos,$ypos+16], -size=> [150,13+2],
);
my $PitchIMCtau_label= $f_Tab{setup}->AddLabel( -name=> 'PitchIMUtau_label', -font=> $StdWinFont,
  -text=> 'tau =', -pos=> [$xpos,$ypos+32], -size=> [150,13+2],
);

$xpos= 30+(2)*$OPTIONSWIDTH_X;
$ypos= 10 + (6)*$OPTIONSWIDTH_Y;
my $RollIMCf0_label= $f_Tab{setup}->AddLabel( -name=> 'RollIMUf0_label', -font=> $StdWinFont,
  -text=> '  f0 =', -pos=> [$xpos,$ypos], -size=> [150,13+2],
);
my $RollIMCd_label= $f_Tab{setup}->AddLabel( -name=> 'RollIMUd_label', -font=> $StdWinFont,
  -text=> '   d =', -pos=> [$xpos,$ypos+16], -size=> [150,13+2],
);
my $RollIMCtau_label= $f_Tab{setup}->AddLabel( -name=> 'RollIMUtau_label', -font=> $StdWinFont,
  -text=> 'tau =', -pos=> [$xpos,$ypos+32], -size=> [150,13+2],
);

$xpos= 30+(3)*$OPTIONSWIDTH_X;
$ypos= 10 + (6)*$OPTIONSWIDTH_Y;
my $YawIMCf0_label= $f_Tab{setup}->AddLabel( -name=> 'YawIMUf0_label', -font=> $StdWinFont,
  -text=> '  f0 =', -pos=> [$xpos,$ypos], -size=> [150,13+2],
);
my $YawIMCd_label= $f_Tab{setup}->AddLabel( -name=> 'YawIMUd_label', -font=> $StdWinFont,
  -text=> '   d =', -pos=> [$xpos,$ypos+16], -size=> [150,13+2],
);
my $YawIMCtau_label= $f_Tab{setup}->AddLabel( -name=> 'YawIMUtau_label', -font=> $StdWinFont,
  -text=> 'tau =', -pos=> [$xpos,$ypos+32], -size=> [150,13+2],
);

my $ShowIMCCalculator= 0;
$f_Tab{setup}->AddButton( -name=> 'ShowIMCCalculator',
  -text=> '-', -pos=> [$xsize-41, $tabsize-35], -width=> 12, -height=> 12,
  -flat  => 1,
);

sub ShowIMCCalculator_Click{
  if( $ShowIMCCalculator==0 ){ #unfold
    $ShowIMCCalculator= 1;
    $f_Tab{setup}->ShowIMCCalculator->Text( "-");
    $f_Tab{setup}->PitchIMUf0_label->Show();
    $f_Tab{setup}->PitchIMUd_label->Show();
    $f_Tab{setup}->PitchIMUtau_label->Show();
    $f_Tab{setup}->RollIMUf0_label->Show();
    $f_Tab{setup}->RollIMUd_label->Show();
    $f_Tab{setup}->RollIMUtau_label->Show();
    $f_Tab{setup}->YawIMUf0_label->Show();
    $f_Tab{setup}->YawIMUd_label->Show();
    $f_Tab{setup}->YawIMUtau_label->Show();
  }else{ #fold
    $ShowIMCCalculator= 0;
    $f_Tab{setup}->ShowIMCCalculator->Text( "+");
    $f_Tab{setup}->PitchIMUf0_label->Hide();
    $f_Tab{setup}->PitchIMUd_label->Hide();
    $f_Tab{setup}->PitchIMUtau_label->Hide();
    $f_Tab{setup}->RollIMUf0_label->Hide();
    $f_Tab{setup}->RollIMUd_label->Hide();
    $f_Tab{setup}->RollIMUtau_label->Hide();
    $f_Tab{setup}->YawIMUf0_label->Hide();
    $f_Tab{setup}->YawIMUd_label->Hide();
    $f_Tab{setup}->YawIMUtau_label->Hide();
  }
}

ShowIMCCalculator_Click();

sub SetIMCCalculator{
  my $s= shift;
  if( not defined $NameToOptionHash{$s.' P'} ){ return; }
  if( not defined $NameToOptionHash{$s.' I'} ){ return; }
  if( not defined $NameToOptionHash{$s.' D'} ){ return; }
  my $Kp= $NameToOptionHash{$s.' P'}->{textfield}->Text();
  my $Ki= $NameToOptionHash{$s.' I'}->{textfield}->Text();
  my $Kd= $NameToOptionHash{$s.' D'}->{textfield}->Text();
  my $invKi= divide( 1.0, $Ki );
  my $f0= sqrt( divide( $Ki, 39.4784176*$Kd ) );
  my $d= $Kp * sqrt( divide( 1.0, 4.0*$Kd*$Ki ) );
  if( $s eq 'Pitch' ){
    $PitchIMCf0_label->Text( '  f0 = '. sprintf("%.4g",$f0).' Hz' );
    $PitchIMCd_label->Text( '   d = '.sprintf("%.4f",$d) );
    $PitchIMCtau_label->Text( 'tau = '.sprintf("%.2f",1570.80/(1.0+$Ki)).' ms' );
  }
  if( $s eq 'Roll' ){
    $RollIMCf0_label->Text( '  f0 = '. sprintf("%.4g",$f0).' Hz' );
    $RollIMCd_label->Text( '   d = '.sprintf("%.4f",$d) );
    $RollIMCtau_label->Text( 'tau = '.sprintf("%.2f",1570.80/(1.0+$Ki)).' ms' );
  }
  if( $s eq 'Yaw' ){
    $YawIMCf0_label->Text( '  f0 = '. sprintf("%.4g",$f0).' Hz' );
    $YawIMCd_label->Text( '   d = '.sprintf("%.4f",$d) );
    $YawIMCtau_label->Text( 'tau = '.sprintf("%.2f",1570.80/(1.0+$Ki)).' ms' );
  }
}

sub SetPanModeSetting{
#  my $text= $Option->{textfield}->Text();
  my $text= shift;
  if( not defined $NameToOptionHash{ 'Pan Mode Setting #1' } ){ return; }
  if( not defined $NameToOptionHash{ 'Pan Mode Setting #2' } ){ return; }
  if( not defined $NameToOptionHash{ 'Pan Mode Setting #3' } ){ return; }
  if( $text =~ /off/ ){ #modes enabled: default disabled: #1,#2,#3
    $NameToOptionHash{ 'Pan Mode Setting #1' }->{textfield}->Disable();
    $NameToOptionHash{ 'Pan Mode Setting #2' }->{textfield}->Disable();
    $NameToOptionHash{ 'Pan Mode Setting #3' }->{textfield}->Disable();
  }elsif( ($text =~ /But/)or($text =~ /Aux-[012] /) ){ #modes enabled: default,#1 disabled: #2,#3
    $NameToOptionHash{ 'Pan Mode Setting #1' }->{textfield}->Enable();
    $NameToOptionHash{ 'Pan Mode Setting #2' }->{textfield}->Disable();
    $NameToOptionHash{ 'Pan Mode Setting #3' }->{textfield}->Disable();
  }else{ #modes enabled: default,#1,#2,#3
    $NameToOptionHash{ 'Pan Mode Setting #1' }->{textfield}->Enable();
    $NameToOptionHash{ 'Pan Mode Setting #2' }->{textfield}->Enable();
    $NameToOptionHash{ 'Pan Mode Setting #3' }->{textfield}->Enable();
  }
}

sub SetIRCameraSetting{
#  my $text= $Option->{textfield}->Text();
  my $text= shift;
  if( not defined $NameToOptionHash{ 'Camera Model' } ){ return; }
  if( not defined $NameToOptionHash{ 'IR Camera Setting #1' } ){ return; }
  if( not defined $NameToOptionHash{ 'IR Camera Setting #2' } ){ return; }
  if( not defined $NameToOptionHash{ 'Time Interval (0 = off)' } ){ return; }
  if( $text =~ /off/ ){ #modes enabled: none  disabled: #1,#2
    $NameToOptionHash{ 'Camera Model' }->{textfield}->Disable();
    $NameToOptionHash{ 'IR Camera Setting #1' }->{textfield}->Disable();
    $NameToOptionHash{ 'IR Camera Setting #2' }->{textfield}->Disable();
    $NameToOptionHash{ 'Time Interval (0 = off)' }->{textfield}->Disable();
  }elsif( ($text =~ /But/)or($text =~ /Aux-[012] /) ){ #modes enabled: #1 disabled: #2
    $NameToOptionHash{ 'Camera Model' }->{textfield}->Enable();
    $NameToOptionHash{ 'IR Camera Setting #1' }->{textfield}->Enable();
    $NameToOptionHash{ 'IR Camera Setting #2' }->{textfield}->Disable();
    $NameToOptionHash{ 'Time Interval (0 = off)' }->{textfield}->Enable();
  }else{ #modes enabled: #1,#2
    $NameToOptionHash{ 'Camera Model' }->{textfield}->Enable();
    $NameToOptionHash{ 'IR Camera Setting #1' }->{textfield}->Enable();
    $NameToOptionHash{ 'IR Camera Setting #2' }->{textfield}->Enable();
    $NameToOptionHash{ 'Time Interval (0 = off)' }->{textfield}->Enable();
  }
}

sub SetAccCompensationSetting{
#  my $text= $Option->{textfield}->Text();
  my $text= shift;
#  if( not defined $NameToOptionHash{ 'Imu Acc Threshold (0 = off)' } ){ return; }
#  if( not defined $NameToOptionHash{ 'Acc Noise Level' } ){ return; }
#  if( not defined $NameToOptionHash{ 'Acc Threshold (0 = off)' } ){ return; }
#  if( not defined $NameToOptionHash{ 'Acc Vertical Weight' } ){ return; }
#  if( not defined $NameToOptionHash{ 'Acc Zentrifugal Correction' } ){ return; }
#  if( not defined $NameToOptionHash{ 'Acc Recover Time' } ){ return; }
  if( $text =~ /advanced/ ){
#    $NameToOptionHash{ 'Imu Acc Threshold (0 = off)' }->{textfield}->Disable();
#    $NameToOptionHash{ 'Acc Noise Level' }->{textfield}->Enable();
#    $NameToOptionHash{ 'Acc Threshold (0 = off)' }->{textfield}->Enable();
#    $NameToOptionHash{ 'Acc Vertical Weight' }->{textfield}->Enable();
#    $NameToOptionHash{ 'Acc Zentrifugal Correction' }->{textfield}->Enable();
#    $NameToOptionHash{ 'Acc Recover Time' }->{textfield}->Enable();
  }else{
#    $NameToOptionHash{ 'Imu Acc Threshold (0 = off)' }->{textfield}->Enable();
#    $NameToOptionHash{ 'Acc Noise Level' }->{textfield}->Disable();
#    $NameToOptionHash{ 'Acc Threshold (0 = off)' }->{textfield}->Disable();
#    $NameToOptionHash{ 'Acc Vertical Weight' }->{textfield}->Disable();
#    $NameToOptionHash{ 'Acc Zentrifugal Correction' }->{textfield}->Disable();
#    $NameToOptionHash{ 'Acc Recover Time' }->{textfield}->Disable();
  }
}

sub SetIMU2Setting{
#  my $text= $Option->{textfield}->Text();
  my $text= shift;
#  if( not defined $NameToOptionHash{ 'Pitch FeedForward Gain (0=off)' } ){ return; }
#  if( not defined $NameToOptionHash{ 'Roll FeedForward Gain (0=off)' } ){ return; }
#  if( not defined $NameToOptionHash{ 'Yaw FeedForward Gain (0=off)' } ){ return; }
#  if( not defined $NameToOptionHash{ 'Imu2 FeedForward LPF' } ){ return; }
  if( $text =~ /off/ ){
#    $NameToOptionHash{ 'Pitch FeedForward Gain (0=off)' }->{textfield}->Disable();
#    $NameToOptionHash{ 'Roll FeedForward Gain (0=off)' }->{textfield}->Disable();
#    $NameToOptionHash{ 'Yaw FeedForward Gain (0=off)' }->{textfield}->Disable();
#    $NameToOptionHash{ 'Imu2 FeedForward LPF' }->{textfield}->Disable();
  }elsif( $text =~ /yaw bracket/ ){
#    $NameToOptionHash{ 'Pitch FeedForward Gain (0=off)' }->{textfield}->Enable();
#    $NameToOptionHash{ 'Roll FeedForward Gain (0=off)' }->{textfield}->Enable();
#    $NameToOptionHash{ 'Yaw FeedForward Gain (0=off)' }->{textfield}->Disable();
#    $NameToOptionHash{ 'Imu2 FeedForward LPF' }->{textfield}->Enable();
  }else{
#    $NameToOptionHash{ 'Pitch FeedForward Gain (0=off)' }->{textfield}->Enable();
#    $NameToOptionHash{ 'Roll FeedForward Gain (0=off)' }->{textfield}->Enable();
#    $NameToOptionHash{ 'Yaw FeedForward Gain (0=off)' }->{textfield}->Enable();
#    $NameToOptionHash{ 'Imu2 FeedForward LPF' }->{textfield}->Enable();
  }
}



#-----------------------------------------------------------------------------#
###############################################################################
### Support Routines to handle main window stuff
###############################################################################
#-----------------------------------------------------------------------------#


sub onScrollSetTextfield{
  my $Option= shift;
  switch( $Option->{type} ){
    case 'OPTTYPE_LISTA' {
       $Option->{textfield}->Text( $Option->{choices}[$Option->{setfield}->GetPos()-65536 - $Option->{min}] );
    }
    case ['OPTTYPE_LISTB'] {
       $Option->{textfield}->Text( $Option->{choices}[$Option->{setfield}->GetPos()-$Option->{min}] );
    }
    case ['OPTTYPE_UC','OPTTYPE_SC','OPTTYPE_UI','OPTTYPE_SI' ] {
      if( defined $Option->{values} ){
        $Option->{textfield}->Text( $Option->{values}[$Option->{setfield}->GetPos()-$Option->{min}] );
      }elsif( defined $Option->{equation} ){
        my $x= $Option->{setfield}->GetPos()*$Option->{steps}; my $s;
        eval $Option->{equation}; if($@){}else{ $Option->{textfield}->Text( $s ); }
      }else{
        $Option->{textfield}->Text( ConvertOptionToStr($Option,$Option->{setfield}->GetPos()*$Option->{steps}) );
      }
    }
  }
  if( $Option->{name} =~ /Pitch [PID]$/ ){ SetIMCCalculator('Pitch');  }
  if( $Option->{name} =~ /Roll [PID]$/ ){ SetIMCCalculator('Roll');  }
  if( $Option->{name} =~ /Yaw [PID]$/ ){ SetIMCCalculator('Yaw');  }
  if( $Option->{name} eq 'Pan Mode Control' ){ SetPanModeSetting($Option->{textfield}->Text()); }
  if( $Option->{name} eq 'IR Camera Control' ){ SetIRCameraSetting($Option->{textfield}->Text()); }
  if( $Option->{name} eq 'Acc Compensation Method' ){ SetAccCompensationSetting($Option->{textfield}->Text()); }
  if( $Option->{name} eq 'Imu2 Configuration' ){ SetIMU2Setting($Option->{textfield}->Text()); }
}

sub ConvertOptionToStr{
  my $Option= shift; my $value= shift;
  my $ppos= $Option->{ppos};
  if( $ppos<0 ){
    for(my $i=0; $i<-$ppos; $i++){ $value= $value*10.0; }
    $ppos= 0;
  }else{
    for(my $i=0; $i<$ppos; $i++){ $value= $value*0.1; }
  }
  return sprintf( "%.".$ppos."f", $value )." ".$Option->{unit};
}


# if option = editable -> onScrollSetTextField
# if option = readonly -> ConvertOptionToStr
#this function takes a numerical value as an unsigned value, converting afterwards it if needed
sub SetOptionField{
  my $Option= shift; my $value= shift;
  switch( $Option->{type} ){
    case ['OPTTYPE_STR'] {
      $value= CleanLeftRightStr($value);
      $Option->{textfield}->Text( $value );
    }
    case 'OPTTYPE_VER' {
      $Option->{textfield}->Text( sprintf("%04i",$value) );
    }
    case ['OPTTYPE_STR+OPTTYPE_READONLY'] {
      $Option->{textfield}->Text( $value );
    }
    case ['OPTTYPE_UC+OPTTYPE_READONLY','OPTTYPE_UI+OPTTYPE_READONLY'] {
      $Option->{textfield}->Text( ConvertOptionToStr($Option,$value) );
    }
    case 'OPTTYPE_SC+OPTTYPE_READONLY' {
      if( $value>127 ){ $value= $value-256; }
      $Option->{textfield}->Text( ConvertOptionToStr($Option,$value) );
    }
    case 'OPTTYPE_SI+OPTTYPE_READONLY' {
      if( $value>32767 ){ $value= $value-65536; }
      $Option->{textfield}->Text( ConvertOptionToStr($Option,$value) );
    }
    case ['OPTTYPE_LISTA'] {
      $Option->{setfield}->SetPos( $value );
      onScrollSetTextfield( $Option );
    }
    case ['OPTTYPE_UC','OPTTYPE_UI','OPTTYPE_LISTB'] {
      $Option->{setfield}->SetPos( $value/$Option->{steps} );
      onScrollSetTextfield( $Option );
    }
    case 'OPTTYPE_SC' {
      if( $value>127 ){ $value= $value-256; }
      $Option->{setfield}->SetPos( $value/$Option->{steps} );
      onScrollSetTextfield( $Option );
    }
    case 'OPTTYPE_SI' {
      if( $value>32767 ){ $value= $value-65536; }
      $Option->{setfield}->SetPos( $value/$Option->{steps} );
      onScrollSetTextfield( $Option );
    }
  }
}

#this function returns a numerical value as an unsigned value, converting it beforehand if needed
sub GetOptionField{
  my $Option= shift;  my $value; my $signcorrect= shift;
  if( not defined  $signcorrect ){ $signcorrect=1; }
  switch( $Option->{type} ){
    case ['OPTTYPE_STR']{
      $value= $Option->{textfield}->Text();
      $value= CleanLeftRightStr($value);
    }
    case ['OPTTYPE_VER','OPTTYPE_STR+OPTTYPE_READONLY',
          'OPTTYPE_UC+OPTTYPE_READONLY','OPTTYPE_UI+OPTTYPE_READONLY']{
      $value= $Option->{textfield}->Text();
    }
    case 'OPTTYPE_SC+OPTTYPE_READONLY' {
      $value= $Option->{textfield}->Text();
      if($signcorrect){ if( $value<0 ){ $value= $value+256; }}
    }
    case 'OPTTYPE_SI+OPTTYPE_READONLY' {
      $value= $Option->{textfield}->Text();
      if($signcorrect){ if( $value<0 ){ $value= $value+65536; } }
    }
    case 'OPTTYPE_LISTA' {
      $value= $Option->{setfield}->GetPos()-65536;
    }
    case ['OPTTYPE_UC','OPTTYPE_UI','OPTTYPE_LISTB']{
      $value= $Option->{setfield}->GetPos()*$Option->{steps};
    }
    case 'OPTTYPE_SC' {
      $value= $Option->{setfield}->GetPos()*$Option->{steps};
      if($signcorrect){ if( $value<0 ){ $value= $value+256; }}
    }
    case 'OPTTYPE_SI' {
      $value= $Option->{setfield}->GetPos()*$Option->{steps};
      if($signcorrect){ if( $value<0 ){ $value= $value+65536; }}
    }
  }
  return $value;
}


sub PopulateOptions{
  my @i; my @j; my $ex;
  for( $ex=0; $ex<$MaxSetupTabs; $ex++ ){
    foreach my $DummyOption (@{$DummyOptionList[$ex]}){
      $DummyOption->{label}->Hide();
      $DummyOption->{textfield_readonly}->Hide();
      $DummyOption->{textfield_str}->Hide();
      $DummyOption->{textfield_updown}->Hide();
      $DummyOption->{updownfield}->Hide();
      $DummyOption->{textfield_slider}->Hide();
      $DummyOption->{sliderfield}->Hide();
      $DummyOption->{infofield}->Hide();
    }
    $i[$ex]= 0; $j[$ex]= 0;
  }
  %NameToOptionHash= ();
  foreach my $Option (@OptionList){
    $NameToOptionHash{$Option->{name}}= $Option; #store option with key name for easier reference
    my $label; my $textfield; my $setfield; my $min= $Option->{min}; my $max= $Option->{max};
    $ex= $Option->{expert};
    if( $ex>=$MaxSetupTabs ){ $ex= $MaxSetupTabs-1; }
    #set xpos, ypos
    if( defined $Option->{column} ){ $i[$ex]= $Option->{column}-1; $j[$ex]= 0; }
    if( defined $Option->{pos} ){ $i[$ex]= $Option->{pos}[0]-1; $j[$ex]= $Option->{pos}[1]-1; }
    $xpos= 20 + $i[$ex]*$OPTIONSWIDTH_X; $ypos= 10 + $j[$ex]*$OPTIONSWIDTH_Y;
    my $DummyNr= $j[$ex] + $i[$ex]*$RowNumber;
    $j[$ex]++;
    # get option
    my $DummyOption= $DummyOptionList[$ex][$DummyNr];
    $DummyOption->{option}= $Option;
    #set label
    $label= $DummyOption->{label};
    $label->Text( $Option->{name} );
    if( not $Option->{hidden} ){ $label->Show(); }
    #set textfield and setfield
    switch( $Option->{type} ){
      #set readonly textfield
      case ['OPTTYPE_STR+OPTTYPE_READONLY','OPTTYPE_VER','OPTTYPE_UC+OPTTYPE_READONLY','OPTTYPE_SC+OPTTYPE_READONLY','OPTTYPE_UI+OPTTYPE_READONLY','OPTTYPE_SI+OPTTYPE_READONLY'] {
        $textfield= $DummyOption->{textfield_readonly};
        $textfield->Show();
        $setfield= undef;
      }
      #set textfield
      case ['OPTTYPE_STR'] {
        $textfield= $DummyOption->{textfield_str};
        $textfield->Show();
        $setfield= undef;
      }
      #set textfield with up/down
      case 'OPTTYPE_LISTA' {
        $textfield= $DummyOption->{textfield_updown};
        $textfield->Show();
        $setfield= $DummyOption->{updownfield};
        $setfield->Show();
        $setfield->SetRange( $min, $max );
      }
      #set textfield with slider
      case ['OPTTYPE_UC','OPTTYPE_SC','OPTTYPE_UI','OPTTYPE_SI','OPTTYPE_LISTB' ] {
        $textfield= $DummyOption->{textfield_slider};
        $textfield->Show();
        $setfield= $DummyOption->{sliderfield};
        $setfield->Show();
        $setfield->SetRange( $min, $max );
        $min= $min/$Option->{steps};
        $max= $max/$Option->{steps};
        $setfield->SetRange( $min, $max );
        for(my $i= 1; $i<4; $i++){ $setfield->SetTic( 0.25*( ($max-$min)*$i )+ $min ); }
      }
    }
    $Option->{label}= $label;
    $Option->{textfield}= $textfield;
    $Option->{setfield}= $setfield;
    if( defined $Option->{startupvalue} ){
      SetOptionField( $Option, $Option->{startupvalue} );
    }else{
      SetOptionField( $Option, $Option->{default} );
    }
  }
  SetPanModeSetting( 'off' );
  SetIRCameraSetting( 'off' );
  SetAccCompensationSetting( 'standard' );
  SetIMU2Setting( 'off' );
}


sub SetOptionsLoaded{
  if(shift==0){
    $OptionsLoaded= 0;
    #$w_Main->m_DataDisplay->Disable();
    $w_Main->m_Write->Disable();
    TextOut( "\r\n".'Please do first a read to get controller settings!'."\r\n" );
    foreach my $Option (@OptionList){
      $Option->{textfield}->Change( -background => $OptionInvalidColor );
      $Option->{textfield}->InvalidateRect( 1 );
    }
    $f_Tab{configimu}->imuc_Write->Disable();
    $f_Tab{configimu}->imuc_StoreInEEprom->Disable();
    $f_Tab{configmotors}->mc_StoreInEEprom->Disable();
    AccCalibrateTabEnable(0);
  }else{
    $OptionsLoaded= 1;
    #$w_Main->m_DataDisplay->Enable();
    $w_Main->m_Write->Enable();
    foreach my $Option (@OptionList){
      $Option->{textfield}->Change( -background => $OptionValidColor );
      $Option->{textfield}->InvalidateRect( 1 );
    }
    $f_Tab{configimu}->imuc_Write->Enable();
    $f_Tab{configimu}->imuc_StoreInEEprom->Enable();
    $f_Tab{configmotors}->mc_StoreInEEprom->Enable();
    AccCalibrateTabEnable(1);
  }
}


#is used in Clear and Flash events, do not confuse with ClearOptionsList();
sub ClearOptions{
  my $flag= shift;
  SetOptionList();
  PopulateOptions();
  if( $flag==1 ){ $w_Main->m_RecieveText->Text(''); }
  SetOptionsLoaded(0);
}


sub DoErrorMessage{
  if( $ErrorStr eq '' ){ return 0; }
  $xpos= 220; $ypos= 10;
  $f_Tab{setup}->AddLabel( -text=> 'Unfortunately, one or more errors occured:', -pos=> [$xpos,$ypos] );
  $ypos+= 20;
  my @ss= split( '\n', $ErrorStr );
  foreach my $s (@ss){
    $f_Tab{setup}->AddLabel( -text=> '- '.$s, -pos=> [$xpos,$ypos], );
    $ypos+= 15;
  }
  $ypos+= 25;
  $f_Tab{setup}->AddLabel( -text=> 'Sorry for the inconvennience.', -pos=> [$xpos,$ypos] );
  return 1;
}

sub TextOut{
  if( $w_Main->m_RecieveText->GetLineCount() > 1000 ){
    my $t= $w_Main->m_RecieveText->Text();
    my $l= length($t);
    my $pos= $l/2;
    while( substr($t,$pos,1) ne "\n" ){ $pos++; }
    $t= substr( $t, $pos, $l );
    $w_Main->m_RecieveText->Clear();
    $w_Main->m_RecieveText->Text( $t );
  }
  $w_Main->m_RecieveText->Append( shift );
}

$w_Main->m_RecieveText->SetLimitText( 60000 );
#TextOut( $w_Main->m_RecieveText->GetLimitText() );

sub TextOut_{
  TextOut( shift );
}

sub WaitForJobDone{
#  my $s= $w_Main->m_RecieveText->GetLine(0); #this helps to avoid the next cmd to be executed too early
}

#sub SyncWindowsEvents{
#  Win32::GUI::DoEvents() >= 0 or die "BLHeliTool closed during processing";
#}



#==============================================================================
# do now what needs to be done for startup

my $r='';
if( defined $IniFile ){
  if( defined $IniFile->val('CONTROLLER','Revison') ){ $r= $IniFile->val( 'CONTROLLER','Revison');  }
}
if( $r ne '' ){
  SetOptionList( $r );
}else{
  SetOptionList(); #options were cleared if error
}
PopulateOptions();
SetOptionsLoaded(0);
#DoErrorMessage();





#==============================================================================
# Event Handler f�r Main

sub m_About_Click{
  $w_Main->MessageBox( "OlliW's Brushless Gimbal Controller Tool ".$BGCStr."Tool\n\n".
  "(c) OlliW @ www.olliw.eu\n\n$VersionStr\n\n".
  'Project web page: http://www.olliw.eu/'."\n\n".
  "TERMS of USAGE:\n".
  "The ".$BGCStr."Tool Windows GUI is open source, and the ".$BGCStr." firmware is free. ".
  "You are explicitely granted the ".
  "permission to use the GUI and the firmwares for commercial purposes under the condition that (1) you don't ".
  "modify the softwares/firmwares, e.g. remove or change copyright ".
  "statements, (2) provide it for free, i.e. don't charge any explicit or ".
  "implicit fees, to your customers, and (3) correctly and clearly ".
  "cite the origin of the softwares/firmwares and the above ".
  "project web page in any product documentation or web page.\n\n".
  "ACKNOWLEDGEMENTS:\n".
  "Special thanks go to hexakopter/Dario, for his endless hours of testing.\n\n"
  ,
  'About' );
  1;
}

#sub m_Help_Click{ ShowHelp('BLHeliTool'); 1; }

sub m_DataDisplay_Click{ ShowDataDisplay(); 1; }

sub m_Window_Terminate{ -1; }

sub m_Window_Minimize{ DataDisplayMinimize(); 1; }

sub m_Window_Activate{ DataDisplayActivate(); 1; }

#sub m_Window_Activate{ DataDisplayMakeVisible(); $w_Main->SetForegroundWindow(); 1; }

sub m_Default_Click{
  foreach my $Option (@OptionList){
    if( OptionToSkip($Option) ){ next; }
    if( defined $Option->{default} ){
      SetOptionField( $Option, $Option->{default} );
    }else{ #sollte eigentlich nicht vorkommen
      if( index($Option->{type},'OPTTYPE_STR')>=0 ){
        SetOptionField( $Option, '' );
      }else{
        SetOptionField( $Option, 0 );
      }
    }
    $Option->{textfield}->Change( -background => $OptionInvalidColor ); #$OptionModifiedColor );
    $Option->{textfield}->InvalidateRect( 1 );
  }
  1;
}

#my $SettingsFile_lastdir= $ExePath; #defined in the above in calibration tab

sub m_OpenSettings_Click{
  my $file= Win32::GUI::GetOpenFileName( -owner=> $w_Main,
    -title=> 'Load Settings from File',
    -nochangedir=> 1,
    -directory=> $SettingsFile_lastdir, #".\\",
    -defaultextension=> '.cfg',
    -filter=> ['*.cfg'=>'*.cfg','All files' => '*.*'],
    -pathmustexist=> 1,
    -filemustexist=> 1,
  );
  if( $file ){
    if( !open(F,"<$file") ){
      $w_Main->MessageBox( "Some error occured, sorry",'ERROR'); return; }
    my $s=''; while(<F>){ $s.= $_; } close(F);
    my %SettingsHash = ();
    eval "$s"; if($@){ %SettingsHash = (); }
    foreach my $Option (@OptionList){
      if( OptionToSkip($Option) ){ next; }
      if( defined $SettingsHash{ $Option->{name} } ){
        TextOut( $Option->{name}." = ok, ".$SettingsHash{ $Option->{name} }[0]."\n");
        SetOptionField( $Option, $SettingsHash{$Option->{name}}[0] );
        $Option->{textfield}->Change( -background => $OptionModifiedColor );
        $Option->{textfield}->InvalidateRect( 1 );
      }else{
        SetOptionField( $Option, $Option->{default} );
        $Option->{textfield}->Change( -background => $OptionInvalidColor );
        $Option->{textfield}->InvalidateRect( 1 );
      }
    }
  }elsif( Win32::GUI::CommDlgExtendedError() ){ $w_Main->MessageBox("Some error occured, sorry",'ERROR'); }
  1;
}

sub m_SaveSettings_Click{
  my $file= Win32::GUI::GetSaveFileName( -owner=> $w_Main,
    -title=> 'Save Settings to File',
    -nochangedir=> 1,
    -directory=> $SettingsFile_lastdir, #".\\",
    -defaultextension=> '.cfg',
    -filter=> ['*.cfg'=>'*.cfg','All files' => '*.*'],
    -pathmustexist=> 1,
    -overwriteprompt=> 1,
    -noreadonlyreturn => 1,
    -explorer=>0,
  );
  if( $file ){
    if( !open(F,">$file") ){
      $w_Main->MessageBox("Some error occured, sorry",'ERROR'); return; }
    print F '%SettingsHash = ('."\n";
    foreach my $Option (@OptionList){
      if( OptionToSkip($Option) ){ next; }
      print F "  '" . $Option->{name} . "' => [ " . GetOptionField($Option) . " , '" . $Option->{textfield}->Text() . "' ],\n";
    }
    print F ');'."\n";
    close(F);
  }elsif( Win32::GUI::CommDlgExtendedError() ){$w_Main->MessageBox("Some error occured, sorry",'ERROR');}
  1;
}

sub m_DefaultSettings_Click{ ExecuteDefault(); SynchroniseConfigTabs(); 1; }

sub m_StoreSettings_Click{ ExecuteStoreToEeprom(); 1; }

sub m_RetrieveSettings_Click{ ExecuteRetrieveFromEeprom(); SynchroniseConfigTabs(); 1; }

sub m_Clear_Click{ ClearOptions(1); SynchroniseConfigTabs(); 1; }

sub m_Exit_Click{ -1; }

sub m_Read_Click{ ExecuteRead(); SynchroniseConfigTabs(); 1; }

sub m_Write_Click{
  if( $w_Main->m_WriteAndStore_check->GetCheck() ){
    ExecuteWrite(1);
    $w_Main->m_WriteAndStore_check->Click();
  }else{
    ExecuteWrite(0);
  }
  1;
}

sub m_Status_Click{
  my $ret= ExecuteGetStatus();
  if( $ret==1){ AccCalibrateTabEnable(1); }
  1;
}

sub t_EraseEeprom_Click{ if(ExecuteEraseEeprom()){ExecuteResetController();} 1; }
#sub t_EraseEeprom_Click{ ExecuteEraseEeprom(); 1; }

sub t_LevelGimbal_Click{ ExecuteLevelGimbal(); 1; }

sub t_ResetController_Click{ ExecuteResetController(); 1; }

sub t_GetCurrentMotorDirections_Click{ ExecuteGetCurrentMotorDirections(); 1; }

sub t_GetCurrentMotorPositions_Click{ ExecuteGetCurrentMotorPositions(); 1; }





#==============================================================================
# Event Handler f�r Flash tab

my $FirmwareHexFileDir_lastdir= $ExePath;

sub m_flash_HexFileDir_button_Click{
  my $file= Win32::GUI::BrowseForFolder( -owner=> $w_Main,
    -title=> 'Select Firmware File Directory',
    -directory=> $FirmwareHexFileDir_lastdir,
    -folderonly=> 1,
  );
  if( $file ){
    $FirmwareHexFileDir_lastdir= $file;
    $f_Tab{flash}->m_flash_HexFileDir->Text( RemoveBasePath($file) );
  }elsif( Win32::GUI::CommDlgExtendedError() ){ $w_Main->MessageBox("Some error occured, sorry",'ERROR'); }
  1;
}

my $FirmwareHexFile_lastdir= $ExePath;

sub m_flash_HexFile_button_Click{
  my $file= Win32::GUI::GetOpenFileName( -owner=> $w_Main,
    -title=> 'Load Firmware File',
    -nochangedir=> 1,
    -directory=> $FirmwareHexFile_lastdir,
    -defaultextension=> '.hex',
    -filter=> ['firmware files'=>'*.hex','*.bin','All files' => '*.*'],
    -pathmustexist=> 1,
    -filemustexist=> 1,
  );
  if( $file ){
    if( !open(F,"<$file") ){ $w_Main->MessageBox( "Some error occured, sorry",'ERROR'); return; }
    close( F );
    $FirmwareHexFile_lastdir= $file;
    $f_Tab{flash}->m_flash_HexFile->Text( RemoveBasePath($file) );
  }elsif( Win32::GUI::CommDlgExtendedError() ){ $w_Main->MessageBox("Some error occured, sorry",'ERROR'); }
  1;
}


sub m_Flash_Click{
  TextOut( "\r\nFlash firmware... Please wait!" );
  my $file= $f_Tab{flash}->m_flash_HexFile->Text();
  if( $file eq '' ){
    TextOut( "\r\nFlash firmware... ABORTED!\r\nFirmware file is not set.\r\n" ); return 1;
  }
  if( !open(F,"<$file") ){
    TextOut( "\r\nFlash firmware... ABORTED!\r\nFirmware file is not existing!\r\n" ); return 1;
  }
  close( F );
  my $programmer= '';
  my $i= $f_Tab{flash}->m_flash_STM32Programmer->GetCurSel();
##flash using STLink
  if( $i == $STLinkIndex ){
    TextOut( "\r\nuse ST-Link/V2 SWD" );
    my $d= '"'.$STLinkPath.'\st-link_cli.exe"';
    my $s= '';
    if(  $f_Tab{flash}->m_flash_FullErase_check->GetCheck() ){
      TextOut( "\r\ndo full chip erase" );
      $s.= $d.' -ME'."\n";
      $f_Tab{flash}->m_flash_FullErase_check->Checked(0);
    }
    $s.= $d.' -P "'.$file.'"';
    if(  $f_Tab{flash}->m_flash_Verify_check->GetCheck() ){
      TextOut( "\r\ndo verify" );
      $s.= ' -V';
    }
    $s.= "\n";
    $s.= $d.' -Rst'."\n";
    $s.='@pause'."\n";
    open(F,">$BGCToolRunFile.bat");
    print F $s;
    close( F );
    TextOut( "\r\nflash firmware..." );
    $w_Main->ShellExecute('open',"$BGCToolRunFile.bat","",'',1);
    TextOut( " ok" );
##flash using SystemBootloader
  }elsif( $i == $SystemBootloaderIndex ){
    my $portnr= substr($f_Tab{flash}->m_flash_STM32ProgrammerComPort->Text(),3,2);
    if( $portnr eq '' ){
      TextOut( "\r\nFlash firmware... ABORTED!\r\nCom port not specified!\r\n" ); return 1;
    }
    TextOut( "\r\nuse System Bootloader @ UART1" );
    my $d= '"'.$STMFlashLoaderPath.'\\'.$STMFlashLoaderExe.'"';
    my $s= $d.' -c --pn '.$portnr.' --br 115200';
    #$s.= ' -i '.'stm32_med-density_128k'; #should be variable!!!!!!!!
    $s.= ' -ow'; #uses modified STMFlashLoaderOlliW
    if(  $f_Tab{flash}->m_flash_FullErase_check->GetCheck() ){
      TextOut( "\r\ndo full chip erase" );
      $f_Tab{flash}->m_flash_FullErase_check->Checked(0);
      $s.= ' -e --all';
      $s.= ' -d --fn "'.$file.'"';
    }else{
      $s.= ' -d --fn "'.$file.'"';
      $s.= ' --ep';
    }
    if(  $f_Tab{flash}->m_flash_Verify_check->GetCheck() ){
      TextOut( "\r\ndo verify" );
      $s.= ' --v';
    }
    $s.= " -r --a 8000000\n";
    $s.= "\n";
    $s.='@echo.'."\n";
    $s.='@pause'."\n";
    open(F,">$BGCToolRunFile.bat");
    print F $s;
    close( F );
    TextOut( "\r\nflash firmware..." );
    $w_Main->ShellExecute('open',"$BGCToolRunFile.bat","",'',1);
    TextOut( " ok" );
  }else{
    TextOut( "\r\nFlash firmware... ABORTED!\r\nSorry, something strange happend!\r\n" ); return 1;
  }
  TextOut( "\r\nFlash firmware... DONE\r\n" );
  1;
}


#==============================================================================
# Further Event Handler

#two columns does not work because messagebox limits maximal width
sub ShareSettings_Click{
  my $s= '';
  my @parameters= ();

  foreach my $Option (@OptionList){
    my $ns= $Option->{name};
    my ($len,$h)= $w_Main->GetTextExtentPoint32( $ns );
    my $ts= '';
    while( $len<200 ){
      $ts.= ' ';
      ($len,$h)= $w_Main->GetTextExtentPoint32( $ns.$ts.' :' );
    }
    $s= $ns.$ts."\t".' : '; #$s.= " ($len) ";
    if( not OptionToSkip($Option) ){
      $s.= GetOptionField($Option,0)."\t".' : ';
    }
    $s.= $Option->{textfield}->Text();
    while( $len<400 ){
      $s.= " ";
      ($len,$h)= $w_Main->GetTextExtentPoint32( $s );
    }
    $s.= "\t";
    push( @parameters, $s );
  }
  $s= "OlliW's Brushless Gimbal Controller Tool ".$BGCStr."Tool\n".
  "$VersionStr\n\n";
  for(my $n=0;$n<3;$n++){ $s.= $parameters[$n]."\n"; }
  my $len= int( (scalar(@parameters)-3)/2+1 );
  #TextOut( "Len:".$len."!");
  for(my $n=0;$n<$len;$n++){
    my $ss= $parameters[3+$n];
    if(3+$len+$n<scalar(@parameters)){ $ss.= $parameters[3+$len+$n]; }
    $ss=~ s/[ \s]*$//;
    $s.= $ss."\n";
  }
  chop($s);
  $w_Main->MessageBox( $s , 'o323BGCTool - Share Settings', 0 );
  1;
}










#-----------------------------------------------------------------------------#
###############################################################################
###############################################################################
# OBGC Routines
###############################################################################
###############################################################################
#-----------------------------------------------------------------------------#
#//capability constants
my $BOARD_HAS_F103CB            = 15; #0x0001
my $BOARD_HAS_F103RB            = 14; #0x0002
my $BOARD_HAS_F103RCDE          = 13; #0x0003
my $BOARD_HAS_F405RG            = 12; #0x0004

my $BOARD_HAS_BATVOLTAGE        =  7; #0x0100
my $BOARD_HAS_ONBOARDMPU        =  6; #0x0200
my $BOARD_HAS_I2C2              =  5; #0x0400
my $BOARD_HAS_RC2               =  4; #0x0800
my $BOARD_HAS_SPEKTRUM          =  3; #0x1000
my $BOARD_HAS_SBUS              =  2; #0x2000
my $BOARD_HAS_IR                =  1; #0x4000
my $BOARD_HAS_3AUX              =  0; #0x8000

my $Error102Str= 'The connected controller board or its firmware version is not supported!';

my $ExecuteIsRunning= 0; #to prevent double clicks
my $DataDisplay_IsRunning= 0;

sub _delay_ms{
  my $tmo= shift;
  $tmo+= $p_Serial->get_tick_count(); #timeout in ms
  do{ }while( $p_Serial->get_tick_count()< $tmo );
}

#uses MAVLINK's x25 checksum
#https://github.com/mavlink/pymavlink/blob/master/mavutil.py
sub do_crc{
  my $bufstr= shift; my $len= shift;
  my @buf= unpack( "C".$len, $bufstr );
##foreach my $b (@buf){ TextOut(UCharToHexstr($b)); } TextOut("!");
  my $crc= 0xFFFF;
  foreach my $b (@buf){
     my $tmp= $b ^ ($crc & 0xFF );
     $tmp= ($tmp ^ ($tmp<<4)) & 0xFF;
     $crc= ($crc>>8) ^ ($tmp<<8) ^ ($tmp<<3) ^ ($tmp>>4);
     $crc= $crc & 0xFFFF;
  }
##TextOut( " CRC:0x".UIntToHexstr($crc)."!" );
  return $crc;
}

sub add_crc_to_data{
  my $datafield= shift;
  my $crc= do_crc( $datafield, length($datafield) );
  #TextOut( " CRC:".UIntToHexstr($crc) );
  $datafield.= pack( "v", $crc );
  #substr($data,1,1) = 'a'; #test to check if error is detected
  return $datafield;
}

sub ConfigPort{
  if( $p_Serial ){
    $p_Serial->baudrate($Baudrate);
    $p_Serial->databits(8);
    $p_Serial->parity("none");
    $p_Serial->stopbits(1);
    $p_Serial->handshake("none");
    $p_Serial->buffers(4096, 4096);
    $p_Serial->write_char_time(0);
    $p_Serial->write_const_time(0);
    #http://msdn.microsoft.com/en-us/library/aa450505.aspx
    if( scalar $ReadIntervalTimeout== 0xffffffff ){ #non-blocking asynchronous read
      $p_Serial->read_interval(0xffffffff);
      $p_Serial->read_char_time(0);
      $p_Serial->read_const_time(0);
    }else{
      $p_Serial->read_interval($ReadIntervalTimeout);          # max time between read char (milliseconds)
      $p_Serial->read_char_time($ReadTotalTimeoutMultiplier);  # avg time between read char
      $p_Serial->read_const_time($ReadTotalTimeoutConstant);   # total = (multiplier * bytes) + constant
    }
    $p_Serial->write_settings;
    _delay_ms(100);
    $p_Serial->purge_all();
    _delay_ms(100);
  }
}

sub OpenPort{
  $Port= $w_Main->m_Port->Text(); #$Port has COM + friendly name
  if( ExtractCom($Port) eq '' ){
    TextOut( "\r\nPort not specified!"."\r\n" ); return 0; #this error should never happen
  }
  $p_Serial = Win32::SerialPort->new( ExtractCom($Port) );
  if( not $p_Serial ){
    TextOut( "\r\nOpening port ".ExtractCom($Port)." FAILED!"."\r\n" ); return 0;
  }else{
    ConfigPort();
    return 1;
  }
  return 0;
}

sub ClosePort{ if( $p_Serial ){ $p_Serial->close; } }

sub FlushPort{ if( $p_Serial ){ $p_Serial->purge_all(); } }

sub WritePort{ $p_Serial->owwrite_overlapped_undef( shift ); }

sub ReadPort{
  if( $ExecuteCmdTimeOut<10 ){ $ExecuteCmdTimeOut=10; }
  my $timeout= 20*$ExecuteCmdTimeOut; #timeout in 100 ms
  if( ComIsBlueTooth($w_Main->m_Port->Text()) ){ $timeout+= 20*10; }
  my $len= 0; #length of response
  if( scalar @_ ){ #there is one parameter
    $len= shift; if( not defined $len ){ $len=0; }elsif( $len<0 ){ $len=0; }
    #my $t= shift; if( defined $t ){ $timeout=$t; }
  }
  if( $len>0 ){ $len+=2; } #take CRC into account  #$len>0 indicates that the command returns more than the end char
  my $cmd= ''; my $count= 0; my $result= '';
  my $tmo= $p_Serial->get_tick_count() + $timeout;
  do{
    if( $p_Serial->get_tick_count() > $tmo  ){ return ''; }
    my ($i, $s) = $p_Serial->owread_overlapped(1);
    $count+= $i;
    $result.= $s;
    if( $len>0 ){
      if( length($result)>=$len ){ $cmd= substr($result,$len,300); }else{ $cmd= ''; }
    }else{
      $cmd= substr($result,length($result)-1,300); #get last char from string
    }
    if( $cmd eq 't' ){ return 't'; }
    if( $cmd eq 'e' ){ return 'e'; }
    if( $cmd eq 'c' ){ return 'c'; }
  }while( $cmd ne "o" );
  my $crc=0;
  if( $len>0 ){
    #check CRC (uses MAVLINK's x25 checksum)
    $crc= unpack( "v", substr($result,$len-2,2) );
    #TextOut( " CRC:".UIntToHexstr($crc) );
    my $crc2= do_crc( $result, $len );
    #TextOut( " CRC2:0x".UIntToHexstr($crc2)."!" );
    #if( $crc ne $crc2 ){ return 'c'; }
    if( $crc2 != 0 ){ return 'c'; }
  }
  return $result; #substr($result,0,length($result)); #keep last indicator byte
}


sub ExecuteCmd{
  WritePort( shift ); #consumes first parameter, is the command!
  return ReadPort( shift ); #consumes second parameter, is the length of expected values!
}


sub CheckConnection{
  TextOut_( "\r\n".'t... ' );
  my $s= ExecuteCmd( 't', 0 );
  if( $s eq 'o' ){
    TextOut_( 'ok' );
    return 1;
  }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED!'."\r\n" );
  }
  return 0;
}


sub GetControllerVersion{
my $version= ''; my $name= ''; my $board= ''; my $layout= ''; my $ver =''; my $capabilities= '';
  TextOut_( "\r\n".'v... ' );
  my $s= ExecuteCmd( 'v', (16)*3 +2+2+2 );
  if( substr($s,length($s)-1,1) eq 'o' ){
    $version= substr($s,0,16);
    $version=~ s/[ \s\0]*$//; #remove blanks&cntrls at end
    $name= substr($s,16,16);
    $name=~ s/[ \s\0]*$//; #remove blanks&cntrls at end
    $board= substr($s,32,16);
    $board=~ s/[ \s\0]*$//; #remove blanks&cntrls at end
    ($ver,$layout,$capabilities)= unpack( "v3", substr($s,48,6) );
    #$capabilities= UIntToBitstr($capabilities);
    #$capabilities= '0x'.UIntToHexstr($capabilities);
    TextOut_( $version );
    #TextOut( " Ver:".$ver."!" );
    #TextOut( " Layout:".$layout."!" );
    #TextOut( " Capabilities:".$capabilities."!" );
  }else{
    TextOut( "\r\n".'Read... ABORTED!' );
  }
  return ($version,$name,$board,$layout);
}


#enter execution state, if needed open port and connect to target
#1: OK,
#100: error-> in calling sub return 0,
#101: error-> in calling sub goto QUICK_END,
#102: layout missmatch,
sub ExecuteHeader{
  if( $ExecuteIsRunning ){ return (100,'','',''); }
  $ExecuteIsRunning= 1;
  my ($Version,$Name,$Board,$Layout)= ('','','','');
  my $msg= shift;
  if( $msg ne '' ){ TextOut("\r\n".$msg) };
  if( not $DataDisplay_IsRunning ){
    if( not OpenPort() ){ ClosePort(); $ExecuteIsRunning= 0; return (100,'','',''); }
    #check connection  TO DO: and synchronize
    #if( not CheckConnection() ){ return (101,'','',''); }
    #check version
    ($Version,$Name,$Board,$Layout)= GetControllerVersion();
    if( $Version eq '' ){ return (101,'','',''); } #a '' indicates an error in GetControllerVersion()
    my $layoutfound= 0;
    foreach my $supportedlayout ( @SupportedBGCLayoutVersions ){
      if( uc($Layout) eq uc($supportedlayout) ){ $layoutfound= 1; last; }
    }
    if( $layoutfound==0 ){ return (102,'','',''); }
  }
  return (1,$Version,$Name,$Board);
}


#finish execution state, if needed close port
sub ExecuteFooter{
  my $RET= shift;
  TextOut( "\r\n" );
  if( not $DataDisplay_IsRunning ){ ClosePort(); }
  $ExecuteIsRunning= 0;
  if( $RET==1 ){ return 1; }
  return 0;
}


#1: OK,
#101: error-> in calling sub goto QUICK_END,
sub ExecuteGetCommand{
  my $Version= shift; my $Name= shift; my $Board= shift; my $DetailsOut= shift;
  my $s=''; my $params='';
  #read options
  TextOut_( "\r\n".'g... ' );
  $s= ExecuteCmd( 'g', $CMD_g_PARAMETER_ZAHL*2 );
  if( substr($s,length($s)-1,1) eq 'o' ){
    $params= StrToHexstr( substr($s,0,length($s)-3) ); #strip off crc and 'o'
#####    TextOut_( $params );
    my $crc= StrToHexstr( substr($s,length($s)-3,2) ); #get crc
#####    TextOut_( " crc:".$crc );
  }else{
    TextOut( "\r\n".'Read... ABORTED!' ); return 101;
  }
  TextOut( "ok" );
  foreach my $Option (@OptionList){
    my $v= OptionToSkip($Option);
    if( $v==1 ){
if( $DataDisplay_IsRunning ){ next; }
      $s= $Version;
    }elsif( $v==2 ){
if( $DataDisplay_IsRunning ){ next; }
      $s= $Name;
    }elsif( $v==3 ){
if( $DataDisplay_IsRunning ){ next; }
      $s= $Board;
    }else{
if($Option->{adr}<0){ next; }
      if($Option->{adr}<10){ $s='0'.$Option->{adr}; }else{ $s= $Option->{adr}; }
      if($DetailsOut){ TextOut_( "\r\n".$s.' -> '.$Option->{name}.': ' ); }
      $s= substr($params,$Option->{adr}*4,4);
      $s= substr($s,2,2).substr($s,0,2); #!!!SWAP BYTES!!!
      if( $Option->{size}<=2 ){ #this is how a STRing is detected, somewhat dirty
        my$ sx= $s;
        $s= HexstrToDez($s);  if($DetailsOut){ TextOut_( "$s "."(0x".$sx.")" ); }
      }else{
        $s= HexstrToStr($s);  if($DetailsOut){ TextOut_( ">$s< " ); }
      }
    }
    SetOptionField( $Option, $s ); #$s is an unsigend value, is converted to signed if need by the function
    WaitForJobDone();
  }
  #done
  SetOptionsLoaded(1);
#  TextOut( "\r\n".'Read... DONE!' );
  return 1;
}


sub ExecuteRead{
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Read... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n"."Read... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  $ret= ExecuteGetCommand( $Version, $Name, $Board, 1 );
  if( $ret==101 ){ goto QUICK_END; }
  TextOut( "\r\n".'Read... DONE!' );
QUICK_END:
  return ExecuteFooter($ret);
}


sub ExecuteWrite{
  my $store_to_eeprom_flag= shift;
  my ($ret,$Version,$Name, $Board)= ExecuteHeader( 'Write... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    $w_Main->MessageBox( "The target seems to have changed.\nDo a read please!", 'WARNING', 0x0000 );
    TextOut( "\r\n".'Write... ABORTED!' ); goto QUICK_END;
  }
  my $s= ''; my $params= ''; my @paramslist= ();
  #read options, this is to ensure that options not handled by GUI are not modified
  TextOut_( "\r\n".'g... ' );
  $s= ExecuteCmd( 'g', $CMD_g_PARAMETER_ZAHL*2 );
  if( substr($s,length($s)-1,1) eq 'o' ){
    $params= StrToHexstr( substr($s,0,length($s)-1) );
    #TextOut_( $params );
    TextOut_( 'ok' );
  }else{
    TextOut( "\r\n".'Write... ABORTED!' ); $ret=0; goto QUICK_END;
  }
  for(my $i=0;$i<$CMD_g_PARAMETER_ZAHL;$i++){ $paramslist[$i]= substr($params,4*$i,4); }
  #@paramslist= split( /(....)/, $params ); #doesn't work reliably
#foreach my $pp (@paramslist){ TextOut( "\r\n!".$pp."?" ); }
  #write
  foreach my $Option( @OptionList ){
    if( OptionToSkip($Option) ){
    }else{
      if($Option->{adr}<0){ next; }
      if($Option->{adr}<10){ $s='0'.$Option->{adr}; }else{ $s= $Option->{adr}; }
      TextOut_( "\r\n".$s.' -> '.$Option->{name}.': ' );
      $s= GetOptionField( $Option ); #$s is an unsigend value, was converted to unsigned by function
      TextOut_( $s );
      #DIRTY: should be done via OPTTYPE
      if( $Option->{size}<=2 ){
        $s= UIntToHexstr($s);
        $s= substr($s,2,2).substr($s,0,2); #!!!SWAP BYTES!!!
        TextOut_( " (0x".$s.")" );
      } #I DO HAVE ONLY 16-bit VALUES HERE!!!
      else{ $s= StrToHexstr( TrimStrToLength($s,$Option->{len}) ); }
      $paramslist[$Option->{adr}]= $s;
    }
  }
#foreach my $pp (@paramslist){ TextOut( "\r\n!".$pp."?" ); }
  my $paramsoutstr= ''; $params= ''; #my $crc= 0;
  foreach (@paramslist){ $params.= $_; $paramsoutstr.= 'x'.$_;}
#  TextOut( "\r\n".'p... '.$paramsoutstr );
#####  TextOut( "\r\n".'!!!!p... '.$params."!!\r\n" );
  $s= HexstrToStr($params); #pack(H*)
  $s= add_crc_to_data( $s );
#####  my $sss= StrToHexstr($s);
#####  TextOut( "\r\n".'p... '.substr($sss,0,length($sss)-4).' crc:'.substr($sss,length($sss)-4,20) );
  TextOut( "\r\n".'p... ' );
  $s= ExecuteCmd( 'p'.$s );
  my $response= substr($s,length($s)-1,1);
  if( $response ne 'o' ){
    TextOut( "\r\n".'Write... ABORTED! ('.$s.')' );
    if( $response eq 't' ){
      TextOut( "\r\n".'Timeout error while writing to controller board!' );
    }elsif( $response eq 'c' ){
      TextOut( "\r\n".'CRC error while writing to controller board!' );
    }elsif( $response eq 'e' ){
      TextOut( "\r\n".'Command error while writing to controller board!' );
    }else{
      TextOut( "\r\n".'Timeout while writing to controller board!' );
    }
    $ret=0; goto QUICK_END;
  }
  foreach my $Option (@OptionList){
    $Option->{textfield}->Change( -background => $OptionValidColor );
    $Option->{textfield}->InvalidateRect( 1 );
  }
  TextOut( "ok" );
  TextOut( "\r\n".'Write... DONE!' );

  if( $store_to_eeprom_flag>0 ){
    TextOut( "\r\n\r\n".'Store to EEPROM... Please wait!' );
    ExecuteStoreToEeprom_wPortOpen();
  }
QUICK_END:
  return ExecuteFooter($ret);
}


my $STATUS_IMU_PRESENT              =  0; #0x8000
my $STATUS_IMU_HIGHADR              =  1; #0x4000
my $STATUS_MAG_PRESENT              =  2; #0x2000
my $STATUS_IMU2_PRESENT             =  3; #0x1000
my $STATUS_IMU2_HIGHADR             =  4; #0x0800
my $STATUS_MAG2_PRESENT             =  5; #0x0400

my $STATUS_LEVEL_FAILED             = 13; #0x0004
my $STATUS_BAT_ISCONNECTED          = 12; #0x0008
my $STATUS_BAT_VOLTAGEISLOW         = 11; #0x0010

my $STATUS_IMU_OK                   = 10; #0x0020
my $STATUS_IMU2_OK                  =  9; #0x0040
my $STATUS_MAG_OK                   =  8; #0x0080
my $STATUS_MAG2_OK                  =  7; #0x0100

my $STATUS2_PAN_YAW                 =  0; #0x8000
my $STATUS2_PAN_ROLL                =  1; #0x4000
my $STATUS2_PAN_PITCH               =  2; #0x2000
my $STATUS2_STANDBY                 =  3; #0x1000
my $STATUS2_IRCAMERA                =  4; #0x0800
my $STATUS2_RECENTER_YAW            =  5; #0x0400
my $STATUS2_RECENTER_ROLL           =  6; #0x0200
my $STATUS2_RECENTER_PITCH          =  7; #0x0100

my $STATE_STARTUP_MOTORS             = 0;
my $STATE_STARTUP_SETTLE             = 1;
my $STATE_STARTUP_CALIBRATE          = 2;
my $STATE_STARTUP_LEVEL              = 3;
my $STATE_STARTUP_MOTORDIRDETECT     = 4;
my $STATE_STARTUP_RELEVEL            = 5;
my $STATE_NORMAL                     = 6;
my $STATE_STANDBY                    = 7;

my @StateText= (   'strtMOTOR', 'SETTLE',  'CALIBRATE', 'LEVEL',     'AUTODIR',   'RELEVEL',   'NORMAL',  'STANDBY',   'unknown','unknown'  );
my @StateColors= ( [255,50,50], [0,0,255], [255,0,255], [80,80,255], [255,0,255], [255,0,255], [0,255,0], [255,50,50], [128,128,128],[128,128,128], );

sub CheckStatus{
  if( substr(shift,shift,1) eq '1' ){ return 1; }else{ return 0; }
}

sub GetState{
  my $state= UIntToBitstr( shift ); #state
  my $i= oct('0b'.substr($state,8,8));
  if( $i<=7 ){
    return ( $StateText[$i], $StateColors[$i], $i );
  }else{
    return ( $StateText[-1], $StateColors[-1], -1 );
  }
}



sub ExecuteGetStatus{
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Get Status... Please wait!' ); #returns $ret=1 if OK
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n"."Get Status... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  TextOut_( "\r\n".'s... ' );
  my $s= ExecuteCmd( 's', 5*2 );
  if( substr($s,length($s)-1,1) eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    $ret=0; goto QUICK_END;
  }

  my @data = unpack( "v$CMD_d_PARAMETER_ZAHL", $s );
  my $s2= UIntToBitstr( $data[1] ); #status
  #TextOut( "\r\n".'0x'.$s.' 0x'.$s2.' -> ' ); #this should be 16bits long
  if( CheckStatus($s2,$STATUS_IMU_PRESENT) ){
    TextOut("\r\n".'  IMU is PRESENT');
    if( CheckStatus($s2,$STATUS_IMU_HIGHADR) ){ TextOut(' @ HIGH ADR'); }else{ TextOut(' @ LOW ADR'); }
  }else{ TextOut("\r\n".'  IMU is not available'); }

  if( CheckStatus($s2,$STATUS_IMU2_PRESENT) ){
    TextOut("\r\n".'  IMU2 is PRESENT');
    if( CheckStatus($s2,$STATUS_IMU2_HIGHADR) ){ TextOut(' @ HIGH ADR = on-board IMU'); }else{ TextOut(' @ LOW ADR = external IMU'); }
  }else{ TextOut("\r\n".'  IMU2 is not available'); }

  if( CheckStatus($s2,$STATUS_MAG_PRESENT) ){ TextOut("\r\n".'  MAG is IMU is OK'); }else{ TextOut("\r\n".'  MAG is not available'); }

  my ($sss)= GetState( $data[0] ); #state
  if( $sss ne '' ){ TextOut("\r\n".'  STATE is '.$sss); }else{ TextOut("\r\n".'  STATE is UNKNOWN!!!!'); }

  TextOut("\r\n".'  BAT is ');
  if( CheckStatus($s2,$STATUS_BAT_ISCONNECTED) ){ TextOut('CONNECTED'); }else{ TextOut('not available'); }
  TextOut(', VOLTAGE is ');
  if( CheckStatus($s2,$STATUS_BAT_VOLTAGEISLOW) ){ TextOut('LOW'); }else{ TextOut('SUFFICIENT'); }
  TextOut(': '.sprintf("%.2f", $data[4]/1000.0).' V' );

  TextOut( "\r\n".'Get Status... DONE!' );
QUICK_END:
  return ExecuteFooter($ret);
}

my $ExecuteCommandFullDelayBeforeGet= 0;

sub ExecuteCommandFullwithGet{
  my $CMD= shift;
  my $MSG= shift;
  my $MSG2= shift;
  my $PARAMZAHL= shift;
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( $MSG.'... Please wait!' ); #return $ret=1 when OK
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n".$MSG."... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  TextOut_( "\r\n".$CMD.'... ' );
  my $s= ExecuteCmd( $CMD, $PARAMZAHL ); #  my $s= ExecuteCmd( 'Cd', $CMD_Cd_PARAMETER_ZAHL*2 );
#  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
  if( substr($s,length($s)-1,1) eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    $ret=0; goto QUICK_END;
  }
  if( $ExecuteCommandFullDelayBeforeGet>0 ){
    TextOut( "\r\n".'Please wait a moment... ' ); _delay_ms($ExecuteCommandFullDelayBeforeGet); TextOut( 'ok' );
  }
  $ExecuteCommandFullDelayBeforeGet=0;
  $ret= ExecuteGetCommand( $Version, $Name, $Board, 0 );
  if( $ret==101 ){ goto QUICK_END; }
  TextOut( "\r\n".$MSG.'... DONE!' );
  if( $MSG2 ne '' ){ TextOut( "\r\n".$MSG2 ); }
QUICK_END:
  return ( ExecuteFooter($ret), $s );
}

sub ExecuteCommandFullwoGet{
  my $CMD= shift;
  my $MSG= shift;
  my $MSG2= shift;
  my $PARAMZAHL= shift;
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( $MSG.'... Please wait!' ); #return $ret=1 when OK
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n".$MSG."... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  TextOut_( "\r\n".$CMD.'... ' );
  my $s= ExecuteCmd( $CMD, $PARAMZAHL ); #  my $s= ExecuteCmd( 'Cd', $CMD_Cd_PARAMETER_ZAHL*2 );
#  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
  if( substr($s,length($s)-1,1) eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    $ret=0; goto QUICK_END;
  }
  if( $ExecuteCommandFullDelayBeforeGet>0 ){
    TextOut( "\r\n".'Please wait a moment... ' ); _delay_ms($ExecuteCommandFullDelayBeforeGet); TextOut( 'ok' );
  }
  $ExecuteCommandFullDelayBeforeGet=0;
  TextOut( "\r\n".$MSG.'... DONE!' );
  if( $MSG2 ne '' ){ TextOut( "\r\n".$MSG2 ); }
QUICK_END:
  return ( ExecuteFooter($ret), $s );
}


sub ExecuteDefault{
  return ExecuteCommandFullwithGet( 'xd', 'Set to Default', '' );
}

sub ExecuteStoreToEeprom_wPortOpen{
  TextOut_( "\r\n".'xs... ' );
  my $s= ExecuteCmd( 'xs' );
  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    goto QUICK_END;
  }
  TextOut( "\r\n".'Store to EEPROM... DONE!' );
QUICK_END:
  return 1;
}

sub ExecuteStoreToEeprom{
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Store to EEPROM... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n"."Store to EEPROM... ABORTED!\r\n".$Error102Str );
    $ret=0; goto QUICK_END;
  }
  ExecuteStoreToEeprom_wPortOpen();
QUICK_END:
  return ExecuteFooter($ret);
}

sub ExecuteRetrieveFromEeprom{
  return ExecuteCommandFullwithGet( 'xr', 'Retrieve from EEPROM', '' );
}

sub ExecuteEraseEeprom{
#####  return ExecuteCommandFullwithGet( 'xc', 'Erase EEPROM', 'NOTE: Please reset or power up the BGC board for proper operation!' );
  return ExecuteCommandFullwoGet( 'xc', 'Erase EEPROM', 'NOTE: Please reset or power up the BGC board for proper operation!' );
}

sub ExecuteLevelGimbal{
  return ExecuteCommandFullwoGet( 'xl', 'Level gimbal', '' );
}

sub ExecuteResetController{
  #handle case if Data Display is running
  my $DataDisplay_WasRunning=  $DataDisplay_IsRunning;
  if( $DataDisplay_IsRunning>0 ){
    DataDisplayStart();
    _delay_ms(1000);
  }
  #now execute the "normal" execution route
##########  ExecuteCommandFullwithGet( 'xx', 'Reset BG controller', '' );
  ExecuteCommandFullwoGet( 'xx', 'Reset BG controller', '' );
  #handle case if Data Display is running
  if( $DataDisplay_WasRunning>0 ){
    _delay_ms(1000);
    DataDisplayStart();
  }
  SetOptionsLoaded(0);
  return 1;
}

sub ExecuteGetCurrentMotorDirections{
  return ExecuteCommandFullwithGet( 'xm', 'Get current motor directions', '' );
}

sub ExecuteGetCurrentMotorPositions{
  return ExecuteCommandFullwithGet( 'xz', 'Get current motor positions', '' );
}

sub ExecuteCalibrateRcTrim{
  $ExecuteCommandFullDelayBeforeGet= 1500;
  return ExecuteCommandFullwithGet( 'CR', 'Calibrate rc trims', '' );
}


#  if( $v<0 ){ $v = $v+65536; } ??????????
sub ExecuteCommandWritewoGet{ #writing of paramters always includes a CRC over the data field
  my $CMD= shift;
  my $MSG= shift;
  my $MSG2= shift;
  my $PARAMS= shift;
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( $MSG.'... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n".$MSG."... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  my $s= $PARAMS;
####  TextOut( "\r\n".'!'.StrToHexstr($s).'!' );
  $s= add_crc_to_data( $s );
####  TextOut( "\r\n".'!'.StrToHexstr($s).'!' );
####  my $crc= do_crc($s, length($s) );
####  TextOut( UIntToHexstr($crc).'!' );
  TextOut( "\r\n".$CMD.'... ' );
  $s= ExecuteCmd( $CMD.$s );
####  TextOut( "\r\n".'!'.StrToHexstr($s).'!' );
  my $response= substr($s,length($s)-1,1);
  if( $response ne 'o' ){
    TextOut( "\r\n".$MSG.'... ABORTED! ('.$s.')' );
    if( $response eq 't' ){
      TextOut( "\r\n".'Timeout error while writing to controller board!' );
    }elsif( $response eq 'c' ){
      TextOut( "\r\n".'CRC error while writing to controller board!' );
    }elsif( $response eq 'e' ){
      TextOut( "\r\n".'Command error while writing to controller board!' );
    }else{
      TextOut( "\r\n".'Timeout while writing to controller board!' );
    }
    $ret=0; goto QUICK_END;
  }
  TextOut( "ok" );
  TextOut( "\r\n".$MSG.'... DONE!' );
QUICK_END:
  return ExecuteFooter($ret);
}














# Ende Main Window
###############################################################################












#-----------------------------------------------------------------------------#
###############################################################################
###############################################################################
# Data Display Window
###############################################################################
###############################################################################
#-----------------------------------------------------------------------------#

$xsize= 725;
$ysize= 525;

my $ddBackgroundColor= [96,96,96];

my $PlotWidth= 600; #4 * 150
my $PlotHeight= 131;
my $PlotAngleRange= 1500;

# NEWVERSION
my $DataFormatStr= 'uuuuu'.'uu'.'sss'.'sss'.'sss'.'sss'.'sss'.'sss'.'sss'.'ss'.'s';
if( length($DataFormatStr)!=$CMD_d_PARAMETER_ZAHL ){ die;}
#_i is the index in the @DataMatrix, _p is the index in the recieved data format
#  data array:              index in DataMatrix        index in 'd' cmd response str
my @DataMicros= ();         my $DataMicro_i= 0;         my $DataMicro_p= 5;
my @DataCycleTime= ();      my $DataCycleTime_i= 1;     my $DataCycleTime_p= 6;

my @DataState= ();          my $DataState_i= 2;         my $DataState_p= 0;
my @DataStatus= ();         my $DataStatus_i= 3;        my $DataStatus_p= 1;
my @DataStatus2= ();        my $DataStatus2_i= 4;       my $DataStatus2_p= 2;
my @DataI2cError= ();       my $DataI2cError_i= 5;      my $DataI2cError_p= 3;
my @DataVoltage= ();        my $DataVoltage_i= 6;       my $DataVoltage_p= 4;

my @DataGx= ();             my $DataGx_i= 7;            my $DataGx_p= 7;
my @DataGy= ();             my $DataGy_i= 8;            my $DataGy_p= 8;
my @DataGz= ();             my $DataGz_i= 9;            my $DataGz_p= 9;

                                                        my $DataAx_p= 10;
                                                        my $DataAy_p= 11;
                                                        my $DataAz_p= 12;

my @DataRx= ();             my $DataRx_i= 10;           my $DataRx_p= 13;
my @DataRy= ();             my $DataRy_i= 11;           my $DataRy_p= 14;
my @DataRz= ();             my $DataRz_i= 12;           my $DataRz_p= 15;

my @DataPitch= ();          my $DataPitch_i= 13;        my $DataPitch_p= 16;
my @DataRoll= ();           my $DataRoll_i= 14;         my $DataRoll_p= 17;
my @DataYaw= ();            my $DataYaw_i= 15;          my $DataYaw_p= 18;

my @DataPitch2= ();         my $DataPitch2_i= 16;       my $DataPitch2_p= 25;
my @DataRoll2= ();          my $DataRoll2_i= 17;        my $DataRoll2_p= 26;
my @DataYaw2= ();           my $DataYaw2_i= 18;         my $DataYaw2_p= 27;

my @DataYawMag= ();         my $DataYawMag_i= 19;       my $DataYawMag_p= 28;
my @DataPitchMag= ();       my $DataPitchMag_i= 20;     my $DataPitchMag_p= 29;

my @DataPitchCntrl= ();     my $DataPitchCntrl_i= 21;   my $DataPitchCntrl_p= 19;
my @DataRollCntrl= ();      my $DataRollCntrl_i= 22;    my $DataRollCntrl_p= 20;
my @DataYawCntrl= ();       my $DataYawCntrl_i= 23;     my $DataYawCntrl_p= 21;

my @DataPitchRcIn= ();      my $DataPitchRcIn_i= 24;    my $DataPitchRcIn_p= 22;
my @DataRollRcIn= ();       my $DataRollRcIn_i= 25;     my $DataRollRcIn_p= 23;
my @DataYawRcIn= ();        my $DataYawRcIn_i= 26;      my $DataYawRcIn_p= 24;

my @DataAccConfidence= ();  my $DataAccConfidence_i= 27; my $DataAccConfidence_p= 30;

my @DataIndex= ();          my $DataIndex_i= 28;
my @DataTime= ();           my $DataTime_i= 29;
my @DataAabs= ();           my $DataAabs_i= 30;

my @DataMatrix = (
      \@DataMicros, \@DataCycleTime, @DataState, @DataStatus, @DataStatus2, \@DataI2cError, \@DataVoltage,
      \@DataGx, \@DataGy, \@DataGz,
      \@DataRx, \@DataRy, \@DataRz,

      \@DataPitch, \@DataRoll, \@DataYaw,
#these need to come right after IMU1 angle data for Paint loop to work  NEWVERSION
      \@DataPitch2, \@DataRoll2, \@DataYaw2,
      \@DataYawMag, \@DataPitchMag,

      \@DataPitchCntrl, \@DataRollCntrl, \@DataYawCntrl,
      \@DataPitchRcIn, \@DataRollRcIn, \@DataYawRcIn,

      \@DataAccConfidence, \@DataIndex, \@DataTime, \@DataAabs,
  );

my $DataPos= 0;
my $DataCounter= 0;
my $DataTimeCounter= 0;
my $DataBlockPos= 0;
my $penPlot = new Win32::GUI::Pen( -color => [0,0,0], -width => 1); #black
my $brushPlot = new Win32::GUI::Brush( [191,191,191] ); #lightgray
my $brushPlotFrame = new Win32::GUI::Brush( [0,0,0] );  #white
my $penGrid= new Win32::GUI::Pen( -color=> [127,127,127], -width=> 1);
my $penZero= new Win32::GUI::Pen( -color=> [0,0,0], -width=> 1);
my $fontLabel= Win32::GUI::Font->new(-name=>'Lucida Console',-size=>9);

#rot, gr�n, blau, grey, greygrey,
my @GraphColors= ( [255,50,50], [0,255,0], [0,0,255], [128,128,128], [64,196,196], #[64,64,64],
                   [192,0,0], [0,128,0], [0,255,255], [0,0,0]);

my @LipoVoltageText= (   'OK', 'LOW',  ' ' );
my @LipoVoltageColors= ( [0,255,0], [255,50,50], [128,128,128]); #gr�n, rot, grau

my @ImuStatusText= (   'ERR', 'OK', 'none', ' ' );
my @ImuStatusColors= ( [255,50,50], [0,255,0], [128,128,128], [128,128,128]); #rot, gr�n, grau

my @Imu2StatusText= (   'ERR', 'OK', 'none', ' ' );
my @Imu2StatusColors= ( [128,128,128], [0,255,0], [128,128,128], [128,128,128]); #rot, gr�n, grau

my @MagStatusText= (   'ERR', 'OK',  'none', ' ' );
my @MagStatusColors= ( [128,128,128], [0,255,0], [128,128,128], [128,128,128]); #rot, gr�n, grau

my $w_DataDisplay= Win32::GUI::DialogBox->new( -name=> 'm_datadisplay_Window', -font=> $StdWinFont,
  -text=> $BGCStr." Data Display",
  -pos=> [$DataDisplayXPos,$DataDisplayYPos],
  -size=> [$xsize,$ysize],
  -helpbox => 0,
  -background=>$ddBackgroundColor,
);
$w_DataDisplay->SetIcon($Icon);

#sub DataDisplayActivate{}

sub DataDisplayMinimize{ if( $w_DataDisplay->IsVisible() ){ $w_DataDisplay->Minimize(); } }
sub DataDisplayActivate{ if( $w_DataDisplay->IsIconic() ){ $w_DataDisplay->Show(); } }
sub m_datadisplay_Window_Activate{ $w_Main->Show(); 1; }


$ypos= 15;

$w_DataDisplay->AddLabel( -name=> 'dd_State', -font=> $StdWinFont,
  -text=> $StateText[-1], -pos=> [10,$ypos], -width=> 60, -align=>'center', -background=>$StateColors[-1],
);


$ypos= 15;
$xpos= 80;

$w_DataDisplay->AddButton( -name=> 'dd_Start', -font=> $StdWinFont,
  -text=> 'Start', -pos=> [$xpos+375+10,$ypos-3], -width=> 80,
);

$w_DataDisplay->AddButton( -name=> 'dd_Clear', -font=> $StdWinFont,
  -text=> 'Clear', -pos=> [$xpos+530,$ypos-3], -width=> 35,
);

$w_DataDisplay->AddButton( -name=> 'dd_Save', -font=> $StdWinFont,
  -text=> 'Save', -pos=> [$xpos+565,$ypos-3], -width=> 35,
);


$xpos= 80-120 + 40;

$w_DataDisplay->AddLabel( -name=> 'dd_Pitch_label', -font=> $StdWinFont,
  -text=> 'Pitch', -pos=> [$xpos+120,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddTextfield( -name=> 'dd_Pitch', -font=> $StdWinFont,
  -pos=> [$xpos+120+$w_DataDisplay->dd_Pitch_label->Width()+3,$ypos-3], -size=> [55,23],
  -align=> 'center',
);
$w_DataDisplay->AddLabel( -name=> 'dd_Roll_label', -font=> $StdWinFont,
  -text=> 'Roll', -pos=> [$xpos+215,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddTextfield( -name=> 'dd_Roll', -font=> $StdWinFont,
  -pos=> [$xpos+215+$w_DataDisplay->dd_Roll_label->Width()+3,$ypos-3], -size=> [55,23],
  -align=> 'center',
);

$w_DataDisplay->AddLabel( -name=> 'dd_Yaw_label', -font=> $StdWinFont,
  -text=> 'Yaw', -pos=> [$xpos+305,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddTextfield( -name=> 'dd_Yaw', -font=> $StdWinFont,
  -pos=> [$xpos+305+$w_DataDisplay->dd_Yaw_label->Width()+3,$ypos-3], -size=> [55,23],
  -align=> 'center',
);


#$w_DataDisplay->AddLabel( -name=> 'dd_IMUState', -font=> $StdWinFont,
#  -text=> ' ', -pos=> [10+60,$ypos], -width=> 29, -align=>'center', -background=>, $OKStateColors[-1]
#);
$ypos= $ysize-55; #15;
$xpos= 80;

$w_DataDisplay->AddLabel( -name=> 'dd_CycleTime_label', -font=> $StdWinFont,
  -text=> 'Cycle Time', -pos=> [$xpos,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddLabel( -name=> 'dd_CycleTime', -font=> $StdWinFont,
  -pos=> [$xpos+$w_DataDisplay->dd_CycleTime_label->Width()+3,$ypos], -width=> 50,
  -background=>$ddBackgroundColor,
  -align=> 'center',
  -text=>'0 us',
);

$w_DataDisplay->AddLabel( -name=> 'dd_I2CError_label', -font=> $StdWinFont,
  -text=> 'I2C Errors', -pos=> [$xpos+120,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddLabel( -name=> 'dd_I2CError', -font=> $StdWinFont,
  -pos=> [$xpos+120+$w_DataDisplay->dd_I2CError_label->Width()+3,$ypos], -width=> 50,
  -background=>$ddBackgroundColor,
  -align=> 'center',
  -text=>'0',
);

$w_DataDisplay->AddLabel( -name=> 'dd_LipoVoltage_label', -font=> $StdWinFont,
  -text=> 'Bat. Voltage', -pos=> [$xpos+240,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddLabel( -name=> 'dd_LipoVoltage', -font=> $StdWinFont,
  -pos=> [$xpos+240+$w_DataDisplay->dd_LipoVoltage_label->Width()+3,$ypos], -width=> 50,
  -background=>$ddBackgroundColor,
  -align=> 'center',
  -text=>'0 V',
);
$w_DataDisplay->AddLabel( -name=> 'dd_LipoVoltageStatus', -font=> $StdWinFont,
  -text=> $LipoVoltageText[-1],
  -pos=> [$xpos+240+$w_DataDisplay->dd_LipoVoltage_label->Width()+3+50,$ypos], -width=> 28,
  -align=>'center', -background=>, $LipoVoltageColors[-1]
);

$w_DataDisplay->AddLabel( -name=> 'dd_ImuStatus_label', -font=> $StdWinFont,
  -text=> 'IMU', -pos=> [$xpos+420,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddLabel( -name=> 'dd_ImuStatus', -font=> $StdWinFont,
  -text=> $ImuStatusText[-1],
  -pos=> [$xpos+420+$w_DataDisplay->dd_ImuStatus_label->Width()+3,$ypos], -width=> 28,
  -align=>'center', -background=>, $Imu2StatusColors[-1]
);

$w_DataDisplay->AddLabel( -name=> 'dd_Imu2Status_label', -font=> $StdWinFont,
  -text=> 'IMU2', -pos=> [$xpos+420+57,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddLabel( -name=> 'dd_Imu2Status', -font=> $StdWinFont,
  -text=> $Imu2StatusText[-1],
  -pos=> [$xpos+420+57+$w_DataDisplay->dd_Imu2Status_label->Width()+3,$ypos], -width=> 28,
  -align=>'center', -background=>, $Imu2StatusColors[-1]
);

$w_DataDisplay->AddLabel( -name=> 'dd_MagStatus_label', -font=> $StdWinFont,
  -text=> 'MAG', -pos=> [$xpos+420+120,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddLabel( -name=> 'dd_MagStatus', -font=> $StdWinFont,
  -text=> $MagStatusText[-1],
  -pos=> [$xpos+420+120+$w_DataDisplay->dd_MagStatus_label->Width()+3,$ypos], -width=> 28,
  -align=>'center', -background=>, $MagStatusColors[-1]
);


$ypos= 45;
$w_DataDisplay->AddLabel( -name=> 'dd_PlotR_label', -font=> $StdWinFont,
  -text=> 'estimated R', -pos=> [10,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotRx_label', -font=> $StdWinFont,
  -text=> 'Rx', -pos=> [10,$ypos+20], -width=> 60, -align=>'center', -background=>$GraphColors[0],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotRy_label', -font=> $StdWinFont,
  -text=> 'Ry', -pos=> [10,$ypos+40], -width=> 60, -align=>'center', -background=>$GraphColors[1],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotRz_label', -font=> $StdWinFont,
  -text=> 'Rz', -pos=> [10,$ypos+60], -width=> 60, -align=>'center', -background=>[80,80,255],#$GraphColors[2],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotAamp_label', -font=> $StdWinFont,
  -text=> 'Acc Amp', -pos=> [10,$ypos+80], -width=> 60, -align=>'center', -background=>[128,128,128],#$GraphColors[2],
);
my $w_Plot_R= $w_DataDisplay->AddGraphic( -parent=> $w_DataDisplay, -name=> 'dd_PlotR', -font=> $StdWinFont,
    -pos=> [80,$ypos], -size=> [$PlotWidth,$PlotHeight],
    -interactive=> 1,
    -addexstyle => WS_EX_CLIENTEDGE,
);


$w_DataDisplay->AddLabel( -name=> 'dd_RcInPitch', -font=> $StdWinFont,
  -pos=> [$PlotWidth+85,$ypos], -width=> 40,
  -background=>$ddBackgroundColor,
  -align=> 'center',
  -text=>'0',
);
$w_DataDisplay->AddLabel( -name=> 'dd_RcInRoll', -font=> $StdWinFont,
  -pos=> [$PlotWidth+85,$ypos+21], -width=> 40,
  -background=>$ddBackgroundColor,
  -align=> 'center',
  -text=>'0',
);
$w_DataDisplay->AddLabel( -name=> 'dd_RcInYaw', -font=> $StdWinFont,
  -pos=> [$PlotWidth+85,$ypos+42], -width=> 40,
  -background=>$ddBackgroundColor,
  -align=> 'center',
  -text=>'0',
);


$ypos+= 140;
$w_DataDisplay->AddLabel( -name=> 'dd_PlotA_label', -font=> $StdWinFont,
  -text=> 'Angles', -pos=> [10,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotPitch_label', -font=> $StdWinFont,
  -text=> 'Pitch', -pos=> [10,$ypos+20], -width=> 60, -align=>'center', -background=>$GraphColors[0],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotRoll_label', -font=> $StdWinFont,
  -text=> 'Roll', -pos=> [10,$ypos+40], -width=> 60, -align=>'center', -background=>$GraphColors[1],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotYaw_label', -font=> $StdWinFont,
  -text=> 'Yaw', -pos=> [10,$ypos+60], -width=> 60, -align=>'center', -background=>[80,80,255],
);
my $w_Plot_Angle= $w_DataDisplay->AddGraphic( -parent=> $w_DataDisplay, -name=> 'dd_PlotA', -font=> $StdWinFont,
    -pos=> [80,$ypos], -size=> [$PlotWidth,$PlotHeight],
    -interactive=> 1,
    -addexstyle => WS_EX_CLIENTEDGE,
);

$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotPitch_check', -font=> $StdWinFont,
  -pos=> [15,$ypos+80], -size=> [12,12],
  -onClick=> sub{ DrawAngle(); 1;},
);
$w_DataDisplay->dd_PlotPitch_check->Checked(1);
$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotRoll_check', -font=> $StdWinFont,
  -pos=> [15,$ypos+96], -size=> [12,12],
  -onClick=> sub{ DrawAngle(); 1;},
);
$w_DataDisplay->dd_PlotRoll_check->Checked(1);
$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotYaw_check', -font=> $StdWinFont,
  -pos=> [15,$ypos+112], -size=> [12,12],
  -onClick=> sub{ DrawAngle(); 1;},
);
$w_DataDisplay->dd_PlotYaw_check->Checked(1);


$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotPitch2_check', -font=> $StdWinFont,
  -pos=> [15+20,$ypos+80], -size=> [12,12],
  -onClick=> sub{ DrawAngle(); 1;},
);
$w_DataDisplay->dd_PlotPitch2_check->Checked(0);
$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotRoll2_check', -font=> $StdWinFont,
  -pos=> [15+20,$ypos+96], -size=> [12,12],
  -onClick=> sub{ DrawAngle(); 1;},
);
$w_DataDisplay->dd_PlotRoll2_check->Checked(0);
$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotYaw2_check', -font=> $StdWinFont,
  -pos=> [15+20,$ypos+112], -size=> [12,12],
  -onClick=> sub{ DrawAngle(); 1;},
);
$w_DataDisplay->dd_PlotYaw2_check->Checked(0);

$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotPitchMag_check', -font=> $StdWinFont,
  -pos=> [15+40,$ypos+80], -size=> [12,12],
  -onClick=> sub{ DrawAngle(); 1;},
);
$w_DataDisplay->dd_PlotPitchMag_check->Checked(0);
$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotRollMag_check', -font=> $StdWinFont,
  -pos=> [15+40,$ypos+96], -size=> [12,12],
  -onClick=> sub{ DrawAngle(); 1;},
);
$w_DataDisplay->dd_PlotRollMag_check->Checked(0);
$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotYawMag_check', -font=> $StdWinFont,
  -pos=> [15+40,$ypos+112], -size=> [12,12],
  -onClick=> sub{ DrawAngle(); 1;},
);
$w_DataDisplay->dd_PlotYawMag_check->Checked(0);

sub Imu2_CheckBoxes_Enable{
  my $flag= shift;
  #$w_DataDisplay->dd_PlotPitch2_check->Show($flag);
  #$w_DataDisplay->dd_PlotRoll2_check->Show($flag);
  #$w_DataDisplay->dd_PlotYaw2_check->Show($flag);
}
sub Mag_CheckBoxes_Enable{
  my $flag= shift;
  $w_DataDisplay->dd_PlotPitchMag_check->Show($flag);
  $w_DataDisplay->dd_PlotRollMag_check->Show($flag);
  $w_DataDisplay->dd_PlotYawMag_check->Show($flag);
}
Imu2_CheckBoxes_Enable(0);
Mag_CheckBoxes_Enable(0);


$w_DataDisplay->AddButton( -name=> 'dd_PlotA_200', -font=> $StdWinFont,
  -text=> '200�', -pos=> [$PlotWidth+85,$ypos], -width=> 30,
  #group => 1,
  -onClick=> sub{ $PlotAngleRange=20000; DrawAngle(); 1;},
);
$w_DataDisplay->AddButton( -name=> 'dd_PlotA_100', -font=> $StdWinFont,
  -text=> '100�', -pos=> [$PlotWidth+85,$ypos+21], -width=> 30,
  #group => 1,
  -onClick=> sub{ $PlotAngleRange=10000; DrawAngle(); 1;},
);
$w_DataDisplay->AddButton( -name=> 'dd_PlotA_30', -font=> $StdWinFont,
  -text=> '30�', -pos=> [$PlotWidth+85,$ypos+42], -width=> 30,
  -onClick=> sub{ $PlotAngleRange=3000; DrawAngle(); 1;},
  -foreground=>[0,128,128],
);
$w_DataDisplay->AddButton( -name=> 'dd_PlotA_15', -font=> $StdWinFont,
  -text=> '15�', -pos=> [$PlotWidth+85,$ypos+63], -width=> 30,
  -onClick=> sub{ $PlotAngleRange=1500; DrawAngle(); 1; },
);
$w_DataDisplay->AddButton( -name=> 'dd_PlotA_5', -font=> $StdWinFont,
  -text=> '5�', -pos=> [$PlotWidth+85,$ypos+84], -width=> 30,
  -onClick=> sub{ $PlotAngleRange=500; DrawAngle(); 1;},
);
$w_DataDisplay->AddButton( -name=> 'dd_PlotA_1p5', -font=> $StdWinFont,
  -text=> '1.5�', -pos=> [$PlotWidth+85,$ypos+105], -width=> 30,
  -onClick=> sub{ $PlotAngleRange=150; DrawAngle(); 1;},
);


$ypos+= 140;
$w_DataDisplay->AddLabel( -name=> 'dd_PlotC_label', -font=> $StdWinFont,
  -text=> 'Control', -pos=> [10,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotCntrlPitch_label', -font=> $StdWinFont,
  -text=> 'Cntrl Pitch', -pos=> [10,$ypos+20], -width=> 60, -align=>'center', -background=>$GraphColors[0],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotCntrlRoll_label', -font=> $StdWinFont,
  -text=> 'Cntrl Roll', -pos=> [10,$ypos+40], -width=> 60, -align=>'center', -background=>$GraphColors[1],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotCntrlYaw_label', -font=> $StdWinFont,
  -text=> 'Cntrl Yaw', -pos=> [10,$ypos+60], -width=> 60, -align=>'center', -background=>[80,80,255],
);

$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotCntrlPitch_check', -font=> $StdWinFont,
  -pos=> [15,$ypos+80], -size=> [12,12],
  -onClick=> sub{ DrawCntrl(); 1;},
);
$w_DataDisplay->dd_PlotCntrlPitch_check->Checked(1);
$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotCntrlRoll_check', -font=> $StdWinFont,
  -pos=> [15,$ypos+96], -size=> [12,12],
  -onClick=> sub{ DrawCntrl(); 1;},
);
$w_DataDisplay->dd_PlotCntrlRoll_check->Checked(1);
$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotCntrlYaw_check', -font=> $StdWinFont,
  -pos=> [15,$ypos+112], -size=> [12,12],
  -onClick=> sub{ DrawCntrl(); 1;},
);
$w_DataDisplay->dd_PlotCntrlYaw_check->Checked(1);

my $w_Plot_Cntrl= $w_DataDisplay->AddGraphic( -parent=> $w_DataDisplay, -name=> 'dd_PlotC', -font=> $StdWinFont,
    -pos=> [80,$ypos], -size=> [$PlotWidth,$PlotHeight],
    -interactive=> 1,
    -addexstyle => WS_EX_CLIENTEDGE,
);


$w_DataDisplay->AddTimer( 'dd_Timer', 0 );
$w_DataDisplay->dd_Timer->Interval( 50 );


sub Paint{
  my $Plot= shift;
  my $DC= $Plot->GetDC();
  my $GraphYMax= shift;
  my $GraphYMin= -$GraphYMax;
  # setting of Ranges and Regions
  my ( $W, $H )= ($Plot->GetClientRect())[2..3];
  my $plot_region= CreateRectRgn Win32::GUI::Region(0,0,$W,$H);
  # get the DC's
  my $DC2= $DC->CreateCompatibleDC();
  my $bit= $DC->CreateCompatibleBitmap( $W, $H );
  $DC2->SelectObject( $bit );
  # draw the Plot region things: background, labels, xy, plotframe
  $DC2->SelectClipRgn( $plot_region );
  $DC2->SelectObject( $penPlot );
  $DC2->SelectObject( $brushPlot );
  $DC2->PaintRgn( $plot_region );
  $DC2->SelectObject( $fontLabel );
  $DC2->TextColor( [127,127,127] );
  $DC2->BackColor( [191,191,191] );
  # draw the Graph region things: frame, grids, zeros, datapoints
  my $DataNr= 0;
  my $DataIndex= 0;
  $DC2->SelectObject( $penZero );
  my $ly= $H*( 0-$GraphYMax)/($GraphYMin-$GraphYMax);
  $DC2->Line( 0, $ly, $W, $ly );
  $DC2->SelectObject( $penGrid );
  if($Plot==$w_Plot_R){
    $DataNr= 5; $DataIndex= $DataRx_i;
    $ly= $H*( 10000-$GraphYMax)/($GraphYMin-$GraphYMax);
    $DC2->Line( 0, $ly, $W, $ly );
    $ly= $H*( -10000-$GraphYMax)/($GraphYMin-$GraphYMax);
    $DC2->Line( 0, $ly, $W, $ly );
  }elsif($Plot==$w_Plot_Angle){
    $DataNr= 6; $DataIndex= $DataPitch_i;
    if($GraphYMax>9000){
      $ly= $H*( 9000-$GraphYMax)/($GraphYMin-$GraphYMax);
      $DC2->Line( 0, $ly, $W, $ly );
      $DC2->TextOut( $PlotWidth-40, $ly-5, '+90�' );
      $ly= $H*( -9000-$GraphYMax)/($GraphYMin-$GraphYMax);
      $DC2->Line( 0, $ly, $W, $ly );
      $DC2->TextOut( $PlotWidth-40, $ly-5, '-90�' );
    }elsif($GraphYMax>1000){
      $ly= $H*( 1000-$GraphYMax)/($GraphYMin-$GraphYMax);
      $DC2->Line( 0, $ly, $W, $ly );
      $DC2->TextOut( $PlotWidth-40, $ly-5, '+10�' );
      $ly= $H*( -1000-$GraphYMax)/($GraphYMin-$GraphYMax);
      $DC2->Line( 0, $ly, $W, $ly );
      $DC2->TextOut( $PlotWidth-40, $ly-5, '-10�' );
    }else{
      $ly= $H*( 100-$GraphYMax)/($GraphYMin-$GraphYMax);
      $DC2->Line( 0, $ly, $W, $ly );
      $DC2->TextOut( $PlotWidth-33, $ly-5, '+1�' );
      $ly= $H*( -100-$GraphYMax)/($GraphYMin-$GraphYMax);
      $DC2->Line( 0, $ly, $W, $ly );
      $DC2->TextOut( $PlotWidth-33, $ly-5, '-1�' );
    }
  }elsif($Plot==$w_Plot_Cntrl){
    $DataNr= 3; $DataIndex= $DataPitchCntrl_i;
    $ly= $H*( 3000-$GraphYMax)/($GraphYMin-$GraphYMax);
    $DC2->Line( 0, $ly, $W, $ly );
    $DC2->TextOut( 560, $ly-5, '+30�' );
    $ly= $H*( -3000-$GraphYMax)/($GraphYMin-$GraphYMax);
    $DC2->Line( 0, $ly, $W, $ly );
    $DC2->TextOut( 560, $ly-5, '-30�' );
  }
  # draw the Data points
  my $DataMatrixLength= scalar @{$DataMatrix[0]};
#  for(my $DataOfs=0; $DataOfs<$DataNr; $DataOfs++ ){
  for(my $DataOfs=$DataNr-1; $DataOfs>=0; $DataOfs-- ){
    my $i= $DataIndex + $DataOfs;
    if($Plot==$w_Plot_R){
      if( $DataOfs==3 ){ $i= $DataAabs_i; }
      if( $DataOfs>=4 ){ $i= $DataAccConfidence_i; }
    }
    if($Plot==$w_Plot_Angle){
      if(( $DataOfs==0 )and( not $w_DataDisplay->dd_PlotPitch_check->Checked() )){ next; }
      if(( $DataOfs==1 )and( not $w_DataDisplay->dd_PlotRoll_check->Checked() )){ next; }
      if(( $DataOfs==2 )and( not $w_DataDisplay->dd_PlotYaw_check->Checked() )){ next; }

      if(( $DataOfs==3 )and( not $w_DataDisplay->dd_PlotPitch2_check->Checked() )){ next; }
      if(( $DataOfs==4 )and( not $w_DataDisplay->dd_PlotRoll2_check->Checked() )){ next; }
      if(( $DataOfs==5 )and( not $w_DataDisplay->dd_PlotYaw2_check->Checked() )){ next; }
    }
    if($Plot==$w_Plot_Cntrl){
      if(( $DataOfs==0 )and( not $w_DataDisplay->dd_PlotCntrlPitch_check->Checked() )){ next; }
      if(( $DataOfs==1 )and( not $w_DataDisplay->dd_PlotCntrlRoll_check->Checked() )){ next; }
      if(( $DataOfs==2 )and( not $w_DataDisplay->dd_PlotCntrlYaw_check->Checked() )){ next; }
    }
    my $ColorOfs= $DataOfs;
    if( ($Plot==$w_Plot_Angle)and($DataOfs>=3) ){ $ColorOfs+=2; } #skip grey+greygrey
    my $pen = new Win32::GUI::Pen( -color => $GraphColors[$ColorOfs], -width => 1);
    $DC2->SelectObject( $pen );
    for(my $px=0; $px<$PlotWidth; $px++){
      my $x= $px;
      if( $DataMatrixLength<$PlotWidth ){ #first run, datamatrix not full
        if( $x>=$DataPos ){ last; }
      }else{ #second run, datamatrix filled
        $x= $px + $DataPos + $DataBlockPos;
        if( $x>=$PlotWidth ){ $x-= $PlotWidth; if( $x>=$DataPos ){last;} }
      }
      if(( $x<0 )or( $x>=$PlotWidth)){ TextOut("SHIT!");}
      my $y= $DataMatrix[$i][$x];
      if( $y>$GraphYMax ){ $y=$GraphYMax; }
      if( $y<$GraphYMin ){ $y=$GraphYMin; }
      my $py= $H*( $y-$GraphYMax)/($GraphYMin-$GraphYMax);
      if( $px==0 ){ $DC2->MoveTo( $px, $py ); }else{ $DC2->LineTo( $px, $py ); }
      $DC2->Rectangle($px-1,$py-1,$px+1,$py+1);
    }
  }
  # update the screen in one action, and clean up
  $DC->BitBlt(0,0,$W,$H,$DC2,0,0);
  $DC2->DeleteDC();
  $DC->Validate();
}

sub DataDisplayClear{
  $DataPos= 0;
  @DataMicros= (); @DataCycleTime= (); @DataState= ();
  @DataRx= (); @DataRy= (); @DataRz= (); @DataPitch= (); @DataRoll= (); @DataYaw= ();
  @DataPitch2= (); @DataRoll2= (); @DataYaw2= ();
  @DataPitchMag= (); @DataYawMag= ();
  @DataPitchCntrl= (); @DataRollCntrl= (); @DataYawCntrl= ();
  @DataPitchRcIn= (); @DataRollRcIn= (); @DataYawRcIn= ();
  @DataAccConfidence= ();
  @DataIndex= (); @DataTime= ();
  $DataCounter= 0;
  $DataBlockPos= 0;
  if(not $DataDisplay_IsRunning){ Draw(); }
  $w_DataDisplay->dd_State->Change( -background => $StateColors[-1] ); #for some reason this has to come before Text()
  $w_DataDisplay->dd_State->Text( $StateText[-1] );
  $w_DataDisplay->dd_LipoVoltageStatus->Change( -background => $LipoVoltageColors[-1] );
  $w_DataDisplay->dd_LipoVoltageStatus->Text( $LipoVoltageText[-1] );
  $w_DataDisplay->dd_ImuStatus->Change( -background => $ImuStatusColors[-1] );
  $w_DataDisplay->dd_ImuStatus->Text( $ImuStatusText[-1] );
  $w_DataDisplay->dd_Imu2Status->Change( -background => $Imu2StatusColors[-1] );
  $w_DataDisplay->dd_Imu2Status->Text( $Imu2StatusText[-1] );
  $w_DataDisplay->dd_MagStatus->Change( -background => $MagStatusColors[-1] );
  $w_DataDisplay->dd_MagStatus->Text( $MagStatusText[-1] );

  $w_DataDisplay->dd_RcInPitch->Text( '' );
  $w_DataDisplay->dd_RcInRoll->Text( '' );
  $w_DataDisplay->dd_RcInYaw->Text( '' );
}

sub DataDisplayStart{
  if( $DataDisplay_IsRunning ){ DataDisplayHalt(); }else{ DataDisplayRun(); }
  return 1;
}

sub DataDisplayHalt{
  ClosePort();
  $w_DataDisplay->dd_Start->Text( 'Start' );
  $w_DataDisplay->dd_Save->Enable();
  $DataDisplay_IsRunning= 0;
}
sub DataDisplayRun{
  if( not OpenPort() ){ ClosePort(); return 1; }
  $w_DataDisplay->dd_Start->Text( 'Stop' );
  $w_DataDisplay->dd_Save->Disable();
  $DataDisplay_IsRunning= 1;
}




my $DATA_BLOCK_SIZE= 150; #this is the look ahead lenght in the display

sub DataDisplayDoTimer{
  if( not $DataDisplay_IsRunning){ return 1; }
  #read data frame
  my $s= ExecuteCmd( 'd', $CMD_d_PARAMETER_ZAHL*2 );
  if( substr($s,length($s)-1,1) ne 'o' ){ return 1; }
  my @ddData = unpack( "v$CMD_d_PARAMETER_ZAHL", $s );
  for(my $n=0;$n<$CMD_d_PARAMETER_ZAHL;$n++){
    if( substr($DataFormatStr,$n,1) eq 's' ){ if( $ddData[$n]>32768 ){ $ddData[$n]-=65536; }  }
  }
  #display
  $w_DataDisplay->dd_Pitch->Text( sprintf("%.2f�", $ddData[$DataPitch_p]/100.0) );
  $w_DataDisplay->dd_Roll->Text( sprintf("%.2f�", $ddData[$DataRoll_p]/100.0) );
  $w_DataDisplay->dd_Yaw->Text( sprintf("%.2f�", $ddData[$DataYaw_p]/100.0) );
  $w_DataDisplay->dd_CycleTime->Text( $ddData[$DataCycleTime_p].' us' );
  $w_DataDisplay->dd_I2CError->Text( $ddData[$DataI2cError_p] );
  $w_DataDisplay->dd_LipoVoltage->Text( sprintf("%.2f V", $ddData[$DataVoltage_p]/1000.0) );

  my ($ssss,$sssc)= GetState( $ddData[$DataState_p] );
  $w_DataDisplay->dd_State->Text( $ssss );
  $w_DataDisplay->dd_State->Change( -background => $sssc );

  my $status= UIntToBitstr( $ddData[$DataStatus_p] ); #status
  my $BatStatus= CheckStatus($status,$STATUS_BAT_VOLTAGEISLOW);
  $w_DataDisplay->dd_LipoVoltageStatus->Text( $LipoVoltageText[$BatStatus] );
  $w_DataDisplay->dd_LipoVoltageStatus->Change( -background => $LipoVoltageColors[$BatStatus] );

  my $ImuStatus= CheckStatus($status,$STATUS_IMU_OK);
  my $ImuPresent= CheckStatus($status,$STATUS_IMU_PRESENT);
  my $ImuFlag= $ImuStatus; if( $ImuPresent==0 ){ $ImuFlag= 2; }
  $w_DataDisplay->dd_ImuStatus->Text( $ImuStatusText[$ImuFlag] );
  $w_DataDisplay->dd_ImuStatus->Change( -background => $ImuStatusColors[$ImuFlag] );

  my $Imu2Status= CheckStatus($status,$STATUS_IMU2_OK);
  my $Imu2Present= CheckStatus($status,$STATUS_IMU2_PRESENT);
  my $Imu2Flag= $Imu2Status; if( $Imu2Present==0 ){ $Imu2Flag= 2; }
  $w_DataDisplay->dd_Imu2Status->Text( $Imu2StatusText[$Imu2Flag] );
  $w_DataDisplay->dd_Imu2Status->Change( -background => $Imu2StatusColors[$Imu2Flag] );

  my $MagStatus= CheckStatus($status,$STATUS_MAG_OK);
  my $MagPresent= CheckStatus($status,$STATUS_MAG_PRESENT);
  my $MagFlag= $MagStatus; if( $MagPresent==0 ){ $MagFlag= 2; }
  $w_DataDisplay->dd_MagStatus->Text( $MagStatusText[$MagFlag] );
  $w_DataDisplay->dd_MagStatus->Change( -background => $MagStatusColors[$MagFlag] );

  Imu2_CheckBoxes_Enable($Imu2Status);
  Mag_CheckBoxes_Enable($MagStatus);

  $w_DataDisplay->dd_RcInPitch->Text( $ddData[$DataPitchRcIn_p] );
  $w_DataDisplay->dd_RcInRoll->Text( $ddData[$DataRollRcIn_p] );
  $w_DataDisplay->dd_RcInYaw->Text( $ddData[$DataYawRcIn_p] );

  #time
  $DataMatrix[$DataMicro_i][$DataPos]= $ddData[$DataMicro_p];
  $DataMatrix[$DataCycleTime_i][$DataPos]= $ddData[$DataCycleTime_p];
  $DataMatrix[$DataState_i][$DataPos]= $ddData[$DataState_p];
  $DataMatrix[$DataStatus_i][$DataPos]= $ddData[$DataStatus_p];
  $DataMatrix[$DataStatus2_i][$DataPos]= $ddData[$DataStatus2_p];
  #Gx, Gy, Gz
  $DataMatrix[$DataGx_i][$DataPos]= $ddData[$DataGx_p];
  $DataMatrix[$DataGy_i][$DataPos]= $ddData[$DataGy_p];
  $DataMatrix[$DataGz_i][$DataPos]= $ddData[$DataGz_p];
  #Rx, Ry, Rz
  $DataMatrix[$DataRx_i][$DataPos]= $ddData[$DataRx_p];
  $DataMatrix[$DataRy_i][$DataPos]= $ddData[$DataRy_p];
  $DataMatrix[$DataRz_i][$DataPos]= $ddData[$DataRz_p];
  #Ax, Ay, Az
  $DataMatrix[$DataAabs_i][$DataPos]= sqrt( sqr($ddData[$DataAx_p])+sqr($ddData[$DataAy_p])+sqr($ddData[$DataAz_p]) );
  $DataMatrix[$DataAccConfidence_i][$DataPos]= $ddData[$DataAccConfidence_p];
  #Pitch, Roll, Yaw
  $DataMatrix[$DataPitch_i][$DataPos]= $ddData[$DataPitch_p]; #100=1�
  $DataMatrix[$DataRoll_i][$DataPos]= $ddData[$DataRoll_p];
  $DataMatrix[$DataYaw_i][$DataPos]= $ddData[$DataYaw_p];
  #CntrlPitch, CntrlRoll, CnrlYaw
  $DataMatrix[$DataPitchCntrl_i][$DataPos]= $ddData[$DataPitchCntrl_p]; #100=1�
  $DataMatrix[$DataRollCntrl_i][$DataPos]= $ddData[$DataRollCntrl_p];
  $DataMatrix[$DataYawCntrl_i][$DataPos]= $ddData[$DataYawCntrl_p];
  #Mot0,Mot1,Mot2
  #$DataMatrix[$DataMot0_i][$DataPos]= $ddData[$DataMot0_p];
  #$DataMatrix[$DataMot1_i][$DataPos]= $ddData[$DataMot1_p];
  #$DataMatrix[$DataMot2_i][$DataPos]= $ddData[$DataMot2_p];

  #IMU2 Pitch, Roll, Yaw   NEWVERSION
  $DataMatrix[$DataPitch2_i][$DataPos]= $ddData[$DataPitch2_p]; #100=1�
  $DataMatrix[$DataRoll2_i][$DataPos]= $ddData[$DataRoll2_p];
  $DataMatrix[$DataYaw2_i][$DataPos]= $ddData[$DataYaw2_p];

  #MAG Yaw, Pitch,
  $DataMatrix[$DataPitchMag_i][$DataPos]= $ddData[$DataPitchMag_p];
  $DataMatrix[$DataYawMag_i][$DataPos]= $ddData[$DataYawMag_p];

  $DataMatrix[$DataIndex_i][$DataPos]= $DataCounter;  $DataCounter++;
  if(( $DataPos>0 )and( $DataMatrix[$DataMicro_i][$DataPos]<$DataMatrix[$DataMicro_i][$DataPos-1] )){
    $DataTimeCounter+= 65536;
  }
  $DataMatrix[$DataTime_i][$DataPos]=
    ($DataMatrix[$DataMicro_i][$DataPos] + $DataTimeCounter - $DataMatrix[$DataMicro_i][0])*16.0/1000.0;

  $DataPos++;
  if( $DataPos>=$PlotWidth ){ $DataPos= 0; }
  if( scalar @{$DataMatrix[0]}==$PlotWidth ){
    if( $DataBlockPos ){ $DataBlockPos--; }else{ $DataBlockPos= $DATA_BLOCK_SIZE; }
  }

  Draw();
  return 1;
}


sub DrawR{     Paint($w_Plot_R,20000); }
sub DrawAngle{ Paint($w_Plot_Angle,$PlotAngleRange); }
sub DrawCntrl{ Paint($w_Plot_Cntrl,6000); }

sub Draw{
  DrawR(); DrawAngle(); DrawCntrl();
}

sub ShowDataDisplay{
  $w_DataDisplay->Show();
  Draw();
  $w_DataDisplay->SetForegroundWindow();
}

#sub DataDisplayMakeVisible{
#  if( $w_DataDisplay->IsVisible() ){ $w_DataDisplay->SetForegroundWindow(); };
#}

#==============================================================================
# Event Handler f�r Data Display

sub m_datadisplay_Window_Terminate{
  if($DataDisplay_IsRunning){ DataDisplayStart(); }
  $w_DataDisplay->Hide();
  0;
}

sub dd_PlotR_Paint{
  my $DC = shift;
  DrawR();
  $DC->Validate();
}

sub dd_PlotA_Paint{
  my $DC = shift;
  DrawAngle();
  $DC->Validate();
}

sub dd_PlotC_Paint{
  my $DC = shift;
  DrawCntrl();
  $DC->Validate();
}

sub dd_Start_Click{ DataDisplayStart(); 1; }

sub dd_Timer_Timer{ DataDisplayDoTimer(); 1; }

sub dd_Clear_Click{ DataDisplayClear(); 1; }

my $DataDisplayFile_lastdir= $ExePath;

sub dd_Save_Click{
  my $file= Win32::GUI::GetSaveFileName( -owner=> $w_DataDisplay, #$w_Main,
    -title=> 'Save Data Display File',
    -nochangedir=> 1,
    -directory=> $DataDisplayFile_lastdir,
    -defaultextension=> '.dat',
    -filter=> ['*.dat' =>'*.dat','*.txt' =>'*.txt','All files' => '*.*'],
    -pathmustexist=> 1,
    -extensiondifferent=> 1,
    -overwriteprompt=> 1,
    -noreadonlyreturn => 1,
    -explorer=>0,
  );
  if( $file ){
    if( !open(F,">$file") ){ $w_Main->MessageBox( "Some error occured, sorry",'ERROR'); return 1; }
    my $DataMatrixLength= scalar @{$DataMatrix[0]};
    #print F "i\ttime\tmicros\tGx\tGy\tGz\tRx\tRy\tRz\tAccAmp\tPitch\tRoll\tYaw\tNCntrl\tRCntrl\tYCntrl\tMot0\tMot1\tMot2\tstatus\n";
    print F "i\ttime\tmicros".
            "\tGx\tGy\tGz\tRx\tRy\tRz\tAccAmp\tAccConf".
            "\tPitch\tRoll\tYaw\tPCntrl\tRCntrl\tYCntrl\tPitch2\tRoll2\tYaw2".
            "\tstate\n";
    for(my $px=0; $px<$PlotWidth; $px++){
      my $x= $px;
      if( $DataMatrixLength<$PlotWidth ){ #first run, datamatrix not full
        if( $px>=$DataMatrixLength ){ next; }
        $x= $px;
      }else{ #second run, datamatrix filled
        $x= $px + $DataPos;
        if( $x>=$PlotWidth ){ $x-= $PlotWidth; }
      }
      print F int($DataMatrix[$DataIndex_i][$x])."\t";
      print F int($DataMatrix[$DataTime_i][$x]+0.5)."\t";
      print F int($DataMatrix[$DataMicro_i][$x])."\t";

      for(my $n=0; $n<3; $n++ ){ print F int($DataMatrix[$DataGx_i+$n][$x])."\t"; }
      for(my $n=0; $n<3; $n++ ){ print F int($DataMatrix[$DataRx_i+$n][$x])."\t"; }
      print F int($DataMatrix[$DataAabs_i][$x])."\t";
      print F int($DataMatrix[$DataAccConfidence_i][$x])."\t";

      for(my $n=0; $n<3; $n++ ){ print F int($DataMatrix[$DataPitch_i+$n][$x])."\t"; }
      for(my $n=0; $n<3; $n++ ){ print F int($DataMatrix[$DataPitchCntrl_i+$n][$x])."\t"; }
      for(my $n=0; $n<3; $n++ ){ print F int($DataMatrix[$DataPitch2_i+$n][$x])."\t"; }

      print F UIntToHexstr( $DataMatrix[$DataState_i+0][$x] );
      print F "\n";
    }
    close(F);

    $DataDisplayFile_lastdir= $file;
  }elsif( Win32::GUI::CommDlgExtendedError() ){ $w_Main->MessageBox("Some error occured, sorry",'ERROR'); return 1;}
  1;
}


# Ende Data Display Window
###############################################################################





















#-----------------------------------------------------------------------------#
###############################################################################
###############################################################################
# ACC 1-POINT CALIBRATION Tool Window
###############################################################################
###############################################################################
#-----------------------------------------------------------------------------#

my $Acc16PCalibration_IsRunning= 0;
my $Acc16PCalibration_ImuNr= 0; #0: Imu, 1: Imu2
my $Acc16PCalibration_Is1Point= 1;

my $Acc16PCalXPos= 80;
my $Acc16PCalYPos= 80;
my $Acc16PCalXSize= 600;
my $Acc16PCalYSize= 480;

$xsize= $Acc16PCalXSize;
$ysize= $Acc16PCalYSize;

my $Acc16PCalBackgroundColor= [96,96,96];

my $CMD_Cd_PARAMETER_ZAHL = 14;

my $CdDataFormatStr= 'sss'.'sss'.'s'.'sss'.'sss'.'s';
if( length($CdDataFormatStr)!=$CMD_Cd_PARAMETER_ZAHL ){ die;}
#_i is the index in the @DataMatrix, _p is the index in the recieved data format
#  data array:              index in DataMatrix        index in 'd' cmd response str
my @CdDataAx= ();           my $CdDataAx_i= 0;          my $CdDataAx_p= 0;
my @CdDataAy= ();           my $CdDataAy_i= 1;          my $CdDataAy_p= 1;
my @CdDataAz= ();           my $CdDataAz_i= 2;          my $CdDataAz_p= 2;
my @CdDataGx= ();           my $CdDataGx_i= 3;          my $CdDataGx_p= 3;
my @CdDataGy= ();           my $CdDataGy_i= 4;          my $CdDataGy_p= 4;
my @CdDataGz= ();           my $CdDataGz_i= 5;          my $CdDataGz_p= 5;
my @CdDataTemp= ();         my $CdDataTemp_i= 6;        my $CdDataTemp_p= 6;

my @CdDataAx2= ();          my $CdDataAx2_i= 7;         my $CdDataAx2_p= 7;
my @CdDataAy2= ();          my $CdDataAy2_i= 8;         my $CdDataAy2_p= 8;
my @CdDataAz2= ();          my $CdDataAz2_i= 9;         my $CdDataAz2_p= 9;
my @CdDataGx2= ();          my $CdDataGx2_i= 10;        my $CdDataGx2_p= 10;
my @CdDataGy2= ();          my $CdDataGy2_i= 11;        my $CdDataGy2_p= 11;
my @CdDataGz2= ();          my $CdDataGz2_i= 12;        my $CdDataGz2_p= 12;
my @CdDataTemp2= ();        my $CdDataTemp2_i= 13;      my $CdDataTemp2_p= 13;

my @CdDataMatrix = (
      \@CdDataAx, \@CdDataAy, \@CdDataAz,     \@CdDataGx, \@CdDataGy, \@CdDataGz,     \@CdDataTemp,
      \@CdDataAx2, \@CdDataAy2, \@CdDataAz2,  \@CdDataGx2, \@CdDataGy2, \@CdDataGz2,  \@CdDataTemp2,
  );


my $CdDataPos= 0; #position in data array
my $CdDataTimeCounter= 0; #slows down update
my $CdDataCounter= 0;

#my @xLipoVoltageText= (   'OK', 'LOW',  ' ' );
my @AccAcceptPointColors= ( $Acc16PCalBackgroundColor, [128,128,255], [255,50,50], [128,128,128]); #std, gr�n, rot, grau

my $w_Acc16PCalibration= Win32::GUI::DialogBox->new( -name=> 'acc16pcal_Window', -parent => $w_Main, -font=> $StdWinFont,
  -text=> $BGCStr." 1-Point Acc Calibration",
  -pos=> [$Acc16PCalXPos,$Acc16PCalYPos],
  -size=> [$xsize,$ysize],
  -helpbox => 0,
  -background=>$Acc16PCalBackgroundColor,
);
$w_Acc16PCalibration->SetIcon($Icon);

$xpos= 5;
$ypos= 5;
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_IntroAAA_label', -font=> $StdWinFont,
  -text=> '1-Point accelerometer calibration for', -pos=> [$xpos,$ypos],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_ImuNr_label', -font=> $StdWinFont,
  -text=> ' Imu (camera IMU) ', -pos=> [$xpos+$w_Acc16PCalibration->acc16pcal_IntroAAA_label->Width()+3,$ypos],
  -background=>[0,255,0], #-foreground=> [0,255,255],
);

$xpos= 40;
$ypos= 10 + 3*13;
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_ax_label', -font=> $StdWinFont,
  -text=> 'ax', -pos=> [$xpos,$ypos],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddTextfield( -name=> 'acc16pcal_ax', -font=> $StdWinFont,
  -pos=> [$xpos+$w_Acc16PCalibration->acc16pcal_ax_label->Width()+3,$ypos-3], -size=> [55,23],
  -align=> 'center',
  -readonly=> 1, -background=>$AccCalibDataColor,
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_ay_label', -font=> $StdWinFont,
  -text=> 'ay', -pos=> [$xpos+90,$ypos],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddTextfield( -name=> 'acc16pcal_ay', -font=> $StdWinFont,
  -pos=> [$xpos+90+$w_Acc16PCalibration->acc16pcal_ay_label->Width()+3,$ypos-3], -size=> [55,23],
  -align=> 'center',
  -readonly=> 1, -background=>$AccCalibDataColor,
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_az_label', -font=> $StdWinFont,
  -text=> 'az', -pos=> [$xpos+180,$ypos],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddTextfield( -name=> 'acc16pcal_az', -font=> $StdWinFont,
  -pos=> [$xpos+180+$w_Acc16PCalibration->acc16pcal_az_label->Width()+3,$ypos-3], -size=> [55,23],
  -align=> 'center',
  -readonly=> 1, -background=>$AccCalibDataColor,
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_temp_label', -font=> $StdWinFont,
  -text=> 'T', -pos=> [$xpos+270,$ypos],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddTextfield( -name=> 'acc16pcal_temp', -font=> $StdWinFont,
  -pos=> [$xpos+270+$w_Acc16PCalibration->acc16pcal_temp_label->Width()+3,$ypos-3], -size=> [55,23],
  -align=> 'center',
  -readonly=> 1, -background=>$AccCalibDataColor,
);

$xpos= 40;
$ypos+= 30;

$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_ax_av', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+$w_Acc16PCalibration->acc16pcal_ax_label->Width()+3,$ypos-3], -size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_ax_sig', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+$w_Acc16PCalibration->acc16pcal_ax_label->Width()+3,$ypos-3 +20], -size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);

$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_ay_av', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+90+$w_Acc16PCalibration->acc16pcal_ay_label->Width()+3,$ypos-3], -size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_ay_sig', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+90+$w_Acc16PCalibration->acc16pcal_ay_label->Width()+3,$ypos-3 +20], -size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);

$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_az_av', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+180+$w_Acc16PCalibration->acc16pcal_az_label->Width()+3,$ypos-3], -size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_az_sig', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+180+$w_Acc16PCalibration->acc16pcal_az_label->Width()+3,$ypos-3 +20], -size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);

$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_temp_av', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+270+$w_Acc16PCalibration->acc16pcal_temp_label->Width()+3,$ypos-3], -size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);

$w_Acc16PCalibration->AddButton( -name=> 'acc16pcal_Start', -font=> $StdWinFont,
  -text=> 'Start', -pos=> [$xpos+375+10,$ypos-3 -30], -width=> 80,
  -onClick => sub{ Acc16PCalibrationStart(); 1; }
);

$xpos= 360;
$ypos= 120 +2*13-10;

$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Zero_label', -font=> $StdWinFont,
  -text=> 'Zero', -pos=> [$xpos-1-30,$ypos+1*13],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Scale_label', -font=> $StdWinFont,
  -text=> 'Scale', -pos=> [$xpos-1-30,$ypos+3*13],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_AccX_label', -font=> $StdWinFont,
  -text=> ' ax', -pos=> [$xpos-1,$ypos-7],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddTextfield( -name=> 'acc16pcal_AccXZero', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos+1*13-4], -size=> [60,23],
  -align=> "right",
  -readonly=> 1, -background=>$AccCalibDataColor,
);
$w_Acc16PCalibration->AddTextfield( -name=> 'acc16pcal_AccXScale', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos+3*13-4], -size=> [60,23],
  -align=> "right",
  -readonly=> 1, -background=>$AccCalibDataColor,
);
$xpos+= 70;
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_AccY_label', -font=> $StdWinFont,
  -text=> ' ay', -pos=> [$xpos-1,$ypos-7],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddTextfield( -name=> 'acc16pcal_AccYZero', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos+1*13-4], -size=> [60,23],
  -align=> "right",
  -readonly=> 1, -background=>$AccCalibDataColor,
);
$w_Acc16PCalibration->AddTextfield( -name=> 'acc16pcal_AccYScale', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos+3*13-4], -size=> [60,23],
  -align=> "right",
  -readonly=> 1, -background=>$AccCalibDataColor,
);
$xpos+= 70;
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_AccZ_label', -font=> $StdWinFont,
  -text=> ' az', -pos=> [$xpos-1,$ypos-7],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddTextfield( -name=> 'acc16pcal_AccZZero', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos+1*13-4], -size=> [60,23],
  -align=> "right",
  -readonly=> 1, -background=>$AccCalibDataColor,
);
$w_Acc16PCalibration->AddTextfield( -name=> 'acc16pcal_AccZScale', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos+3*13-4], -size=> [60,23],
  -align=> "right",
  -readonly=> 1, -background=>$AccCalibDataColor,
);

$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Quality_label', -font=> $StdWinFont,
  -text=> 'quality:', -pos=> [$xpos-140,$ypos+5*13],-width=> 160,
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);

$xpos= 425;
$ypos= 220;

my $Acc16PCalibrationOKCancelButtonPosX= $xpos;
my $Acc16PCalibrationOKCancelButtonPosY= $ypos-3;

$w_Acc16PCalibration->AddButton( -name=> 'acc16pcal_OK', -font=> $StdWinFont,
  -text=> 'OK', -pos=> [$xpos,$ypos-3], -width=> 80,
  -onClick => sub{
      AccCalibrateTabSetCalibration( $w_Acc16PCalibration->acc16pcal_AccXZero->Text(),
                                     $w_Acc16PCalibration->acc16pcal_AccYZero->Text(),
                                     $w_Acc16PCalibration->acc16pcal_AccZZero->Text(),
                                     $w_Acc16PCalibration->acc16pcal_AccXScale->Text(),
                                     $w_Acc16PCalibration->acc16pcal_AccYScale->Text(),
                                     $w_Acc16PCalibration->acc16pcal_AccZScale->Text()
                                    );
      Acc16PCalibrationHalt(); $w_Acc16PCalibration->Hide();
      0; }
);
$w_Acc16PCalibration->AddButton( -name=> 'acc16pcal_Cancel', -font=> $StdWinFont,
  -text=> 'Cancel', -pos=> [$xpos,$ypos-3 +30], -width=> 80,
  -onClick => sub{ Acc16PCalibrationHalt(); $w_Acc16PCalibration->Hide(); 0; }
);

$w_Acc16PCalibration->AddButton( -name=> 'acc16pcal_SaveToFile', -font=> $StdWinFont,
  -text=> 'Save to File', -pos=> [$xpos,$ypos-3 +30 + 45+10], -width=> 80, -height=> 15,
  -onClick => sub{ Acc16PCalibrationSave6PointCalibrationData(); 1; }
);


$xpos= 45;
$ypos= 120 + 3*13-10;

$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point1_label', -font=> $StdWinFont,
  -text=> '1. Point (+Z)', -pos=> [$xpos-15,$ypos], #-size=> [55,23],
  -background=> $Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddButton( -name=> 'acc16pcal_Point1_button', -font=> $StdWinFont,
  -text=> 'Accept current readings', -pos=> [$xpos+50,$ypos-3], -width=> 160,
  -onClick => sub{
      Acc16PCalibrationSetPoint1(
        $w_Acc16PCalibration->acc16pcal_ax_av->Text(),
        $w_Acc16PCalibration->acc16pcal_ay_av->Text(),
        $w_Acc16PCalibration->acc16pcal_az_av->Text() );
      if($Acc16PCalibration_Is1Point){
        Acc16PCalibrationCalc1PointCalibration();
      }else{
        Acc16PCalibrationCalc6PointCalibration();
      }
      1;}
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point1_ax_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point1_ay_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50 + 60,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point1_az_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50 +120,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point1_inRangle', -font=> $StdWinFont,
  -text=> ' -> ', -pos=> [$xpos-40,$ypos], #-size=> [55,23],
  -background=>$AccAcceptPointColors[1], #-foreground=> [255,255,255],
);

$ypos+= 4*13;
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point2_label', -font=> $StdWinFont,
  -text=> '2. Point (-Z)', -pos=> [$xpos-15,$ypos], #-size=> [55,23],
  -background=> $Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddButton( -name=> 'acc16pcal_Point2_button', -font=> $StdWinFont,
  -text=> 'Accept current readings', -pos=> [$xpos+50,$ypos-3], -width=> 160,
  -onClick => sub{
      Acc16PCalibrationSetPoint2(
        $w_Acc16PCalibration->acc16pcal_ax_av->Text(),
        $w_Acc16PCalibration->acc16pcal_ay_av->Text(),
        $w_Acc16PCalibration->acc16pcal_az_av->Text() );
      Acc16PCalibrationCalc6PointCalibration();
      1;}
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point2_ax_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point2_ay_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50 + 60,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point2_az_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50 +120,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point2_inRangle', -font=> $StdWinFont,
  -text=> ' -> ', -pos=> [$xpos-40,$ypos], #-size=> [55,23],
  -background=>$AccAcceptPointColors[1], #-foreground=> [255,255,255],
);

$ypos+= 4*13;
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point3_label', -font=> $StdWinFont,
  -text=> '3. Point (+X)', -pos=> [$xpos-15,$ypos], #-size=> [55,23],
  -background=> $Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddButton( -name=> 'acc16pcal_Point3_button', -font=> $StdWinFont,
  -text=> 'Accept current readings', -pos=> [$xpos+50,$ypos-3], -width=> 160,
  -onClick => sub{
      Acc16PCalibrationSetPoint3(
        $w_Acc16PCalibration->acc16pcal_ax_av->Text(),
        $w_Acc16PCalibration->acc16pcal_ay_av->Text(),
        $w_Acc16PCalibration->acc16pcal_az_av->Text() );
      Acc16PCalibrationCalc6PointCalibration();
      1;}
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point3_ax_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point3_ay_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50 + 60,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point3_az_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50 +120,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point3_inRangle', -font=> $StdWinFont,
  -text=> ' -> ', -pos=> [$xpos-40,$ypos], #-size=> [55,23],
  -background=>$AccAcceptPointColors[1], #-foreground=> [255,255,255],
);

$ypos+= 4*13;
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point4_label', -font=> $StdWinFont,
  -text=> '4. Point (-X)', -pos=> [$xpos-15,$ypos], #-size=> [55,23],
  -background=> $Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddButton( -name=> 'acc16pcal_Point4_button', -font=> $StdWinFont,
  -text=> 'Accept current readings', -pos=> [$xpos+50,$ypos-3], -width=> 160,
  -onClick => sub{
      Acc16PCalibrationSetPoint4(
        $w_Acc16PCalibration->acc16pcal_ax_av->Text(),
        $w_Acc16PCalibration->acc16pcal_ay_av->Text(),
        $w_Acc16PCalibration->acc16pcal_az_av->Text() );
      Acc16PCalibrationCalc6PointCalibration();
      1;}
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point4_ax_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point4_ay_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50 + 60,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point4_az_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50 +120,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point4_inRangle', -font=> $StdWinFont,
  -text=> ' -> ', -pos=> [$xpos-40,$ypos], #-size=> [55,23],
  -background=>$AccAcceptPointColors[1], #-foreground=> [255,255,255],
);

$ypos+= 4*13;
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point5_label', -font=> $StdWinFont,
  -text=> '5. Point (+Y)', -pos=> [$xpos-15,$ypos], #-size=> [55,23],
  -background=> $Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddButton( -name=> 'acc16pcal_Point5_button', -font=> $StdWinFont,
  -text=> 'Accept current readings', -pos=> [$xpos+50,$ypos-3], -width=> 160,
  -onClick => sub{
      Acc16PCalibrationSetPoint5(
        $w_Acc16PCalibration->acc16pcal_ax_av->Text(),
        $w_Acc16PCalibration->acc16pcal_ay_av->Text(),
        $w_Acc16PCalibration->acc16pcal_az_av->Text() );
      Acc16PCalibrationCalc6PointCalibration();
      1;}
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point5_ax_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point5_ay_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50 + 60,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point5_az_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50 +120,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point5_inRangle', -font=> $StdWinFont,
  -text=> ' -> ', -pos=> [$xpos-40,$ypos], #-size=> [55,23],
  -background=>$AccAcceptPointColors[1], #-foreground=> [255,255,255],
);

$ypos+= 4*13;
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point6_label', -font=> $StdWinFont,
  -text=> '6. Point (-Y)', -pos=> [$xpos-15,$ypos], #-size=> [55,23],
  -background=> $Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddButton( -name=> 'acc16pcal_Point6_button', -font=> $StdWinFont,
  -text=> 'Accept current readings', -pos=> [$xpos+50,$ypos-3], -width=> 160,
  -onClick => sub{
      Acc16PCalibrationSetPoint6(
        $w_Acc16PCalibration->acc16pcal_ax_av->Text(),
        $w_Acc16PCalibration->acc16pcal_ay_av->Text(),
        $w_Acc16PCalibration->acc16pcal_az_av->Text() );
      Acc16PCalibrationCalc6PointCalibration();
      1;}
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point6_ax_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point6_ay_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50 + 60,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point6_az_accepted', -font=> $StdWinFont,
  -text=> '---', -pos=> [$xpos+50 +120,$ypos-3 +26], -width=> 55, #-size=> [55,23],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_Point6_inRangle', -font=> $StdWinFont,
  -text=> ' -> ', -pos=> [$xpos-40,$ypos], #-size=> [55,23],
  -background=>$AccAcceptPointColors[1], #-foreground=> [255,255,255],
);


$xpos= 30;
$ypos= 220;
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_1PointHelp', -font=> $StdWinFont,
  -text=> 'Carefully level the imu, with the orientation in which it will be mounted. Keep it at rest,'.
' and watch the acc data. A blue arrow will indicate when they come into range. Wait until the noise'.
' stabilizes at low values, then accept the readings and press OK, or repeat.',
  -pos=> [$xpos,$ypos], -size=> [275,100],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);
$xpos= 310;
$ypos= 360;
$w_Acc16PCalibration->AddLabel( -name=> 'acc16pcal_6PointHelp', -font=> $StdWinFont,
  -text=> 'Carefully position the imu in the six orientations, one by one (the order is irrelevant). Keep it at rest,'.
' and watch the acc data. A blue arrow will indicate when they come into range. Wait until the noise'.
' stabilizes at low values, then accept the readings. When data for all points are recorded press OK, or repeat.',
  -pos=> [$xpos,$ypos], -size=> [270,100],
  -background=>$Acc16PCalBackgroundColor, -foreground=> [255,255,255],
);


$w_Acc16PCalibration->AddTimer( 'acc16pcal_Timer', 0 );
$w_Acc16PCalibration->acc16pcal_Timer->Interval( 10 );

sub acc16pcal_Timer_Timer{ Acc16PCalibrationDoTimer(); 1; }

sub acc16pcal_Window_Terminate{ Acc16PCalibrationHalt(); $w_Acc16PCalibration->Hide(); 0; }

sub caac_Run1PointCalibration_Click{ $Acc16PCalibration_Is1Point = 1; Acc16PCalibrationShow(); 1; }

sub caac_Run6PointCalibration_Click{ $Acc16PCalibration_Is1Point = 0; Acc16PCalibrationShow(); 1; }


sub Acc16PCalibrationHandleWhichPointsToShow{
  if( $Acc16PCalibration_Is1Point==1 ){
  $w_Acc16PCalibration->acc16pcal_Point2_label->Hide();
  $w_Acc16PCalibration->acc16pcal_Point2_button->Hide();
  $w_Acc16PCalibration->acc16pcal_Point2_ax_accepted->Hide();
  $w_Acc16PCalibration->acc16pcal_Point2_ay_accepted->Hide();
  $w_Acc16PCalibration->acc16pcal_Point2_az_accepted->Hide();
  $w_Acc16PCalibration->acc16pcal_Point3_label->Hide();
  $w_Acc16PCalibration->acc16pcal_Point3_button->Hide();
  $w_Acc16PCalibration->acc16pcal_Point3_ax_accepted->Hide();
  $w_Acc16PCalibration->acc16pcal_Point3_ay_accepted->Hide();
  $w_Acc16PCalibration->acc16pcal_Point3_az_accepted->Hide();
  $w_Acc16PCalibration->acc16pcal_Point4_label->Hide();
  $w_Acc16PCalibration->acc16pcal_Point4_button->Hide();
  $w_Acc16PCalibration->acc16pcal_Point4_ax_accepted->Hide();
  $w_Acc16PCalibration->acc16pcal_Point4_ay_accepted->Hide();
  $w_Acc16PCalibration->acc16pcal_Point4_az_accepted->Hide();
  $w_Acc16PCalibration->acc16pcal_Point5_label->Hide();
  $w_Acc16PCalibration->acc16pcal_Point5_button->Hide();
  $w_Acc16PCalibration->acc16pcal_Point5_ax_accepted->Hide();
  $w_Acc16PCalibration->acc16pcal_Point5_ay_accepted->Hide();
  $w_Acc16PCalibration->acc16pcal_Point5_az_accepted->Hide();
  $w_Acc16PCalibration->acc16pcal_Point6_label->Hide();
  $w_Acc16PCalibration->acc16pcal_Point6_button->Hide();
  $w_Acc16PCalibration->acc16pcal_Point6_ax_accepted->Hide();
  $w_Acc16PCalibration->acc16pcal_Point6_ay_accepted->Hide();
  $w_Acc16PCalibration->acc16pcal_Point6_az_accepted->Hide();
  $w_Acc16PCalibration->Resize( $Acc16PCalXSize, $Acc16PCalYSize-160 );
  $w_Acc16PCalibration->acc16pcal_Point1_label->Text( '1. Point' );
  $w_Acc16PCalibration->Text( 'o323BGC 1-Point Acc Calibration' );
  $w_Acc16PCalibration->acc16pcal_IntroAAA_label->Text( '1-Point accelerometer calibration for' );
  $w_Acc16PCalibration->acc16pcal_1PointHelp->Show();
  $w_Acc16PCalibration->acc16pcal_6PointHelp->Hide();

  $w_Acc16PCalibration->acc16pcal_Quality_label->Hide();
  $w_Acc16PCalibration->acc16pcal_OK->Move($Acc16PCalibrationOKCancelButtonPosX,$Acc16PCalibrationOKCancelButtonPosY);
  $w_Acc16PCalibration->acc16pcal_Cancel->Move($Acc16PCalibrationOKCancelButtonPosX,$Acc16PCalibrationOKCancelButtonPosY+30);
  }else{
  $w_Acc16PCalibration->acc16pcal_Point2_label->Show();
  $w_Acc16PCalibration->acc16pcal_Point2_button->Show();
  $w_Acc16PCalibration->acc16pcal_Point2_ax_accepted->Show();
  $w_Acc16PCalibration->acc16pcal_Point2_ay_accepted->Show();
  $w_Acc16PCalibration->acc16pcal_Point2_az_accepted->Show();
  $w_Acc16PCalibration->acc16pcal_Point3_label->Show();
  $w_Acc16PCalibration->acc16pcal_Point3_button->Show();
  $w_Acc16PCalibration->acc16pcal_Point3_ax_accepted->Show();
  $w_Acc16PCalibration->acc16pcal_Point3_ay_accepted->Show();
  $w_Acc16PCalibration->acc16pcal_Point3_az_accepted->Show();
  $w_Acc16PCalibration->acc16pcal_Point4_label->Show();
  $w_Acc16PCalibration->acc16pcal_Point4_button->Show();
  $w_Acc16PCalibration->acc16pcal_Point4_ax_accepted->Show();
  $w_Acc16PCalibration->acc16pcal_Point4_ay_accepted->Show();
  $w_Acc16PCalibration->acc16pcal_Point4_az_accepted->Show();
  $w_Acc16PCalibration->acc16pcal_Point5_label->Show();
  $w_Acc16PCalibration->acc16pcal_Point5_button->Show();
  $w_Acc16PCalibration->acc16pcal_Point5_ax_accepted->Show();
  $w_Acc16PCalibration->acc16pcal_Point5_ay_accepted->Show();
  $w_Acc16PCalibration->acc16pcal_Point5_az_accepted->Show();
  $w_Acc16PCalibration->acc16pcal_Point6_label->Show();
  $w_Acc16PCalibration->acc16pcal_Point6_button->Show();
  $w_Acc16PCalibration->acc16pcal_Point6_ax_accepted->Show();
  $w_Acc16PCalibration->acc16pcal_Point6_ay_accepted->Show();
  $w_Acc16PCalibration->acc16pcal_Point6_az_accepted->Show();
  $w_Acc16PCalibration->Resize( $Acc16PCalXSize, $Acc16PCalYSize );
  $w_Acc16PCalibration->acc16pcal_Point1_label->Text( '1. Point (+Z)' );
  $w_Acc16PCalibration->Text( 'o323BGC 6-Point Acc Calibration' );
  $w_Acc16PCalibration->acc16pcal_IntroAAA_label->Text( '6-Point accelerometer calibration for' );
  $w_Acc16PCalibration->acc16pcal_1PointHelp->Hide();
  $w_Acc16PCalibration->acc16pcal_6PointHelp->Show();

  $w_Acc16PCalibration->acc16pcal_Quality_label->Show();
  $w_Acc16PCalibration->acc16pcal_OK->Move($Acc16PCalibrationOKCancelButtonPosX,$Acc16PCalibrationOKCancelButtonPosY+20);
  $w_Acc16PCalibration->acc16pcal_Cancel->Move($Acc16PCalibrationOKCancelButtonPosX,$Acc16PCalibrationOKCancelButtonPosY+30+20);
  $w_Acc16PCalibration->acc16pcal_SaveToFile->Show();
  }
}


sub Acc16PCalibrationShow{
  if( $DataDisplay_IsRunning ){ DataDisplayStart(); }
  my ($x, $y) = ($w_Main->GetWindowRect())[0..1];
  $w_Acc16PCalibration->Move($x+80,$y+100);
  if( $f_Tab{calibrateacc}->cacc_ImuNumber->GetCurSel()==1 ){ #IMU2 selected
    $Acc16PCalibration_ImuNr= 1;
    $w_Acc16PCalibration->acc16pcal_ImuNr_label->Text( '  Imu2 (2nd IMU)' );
  }else{
    $Acc16PCalibration_ImuNr= 0;
    $w_Acc16PCalibration->acc16pcal_ImuNr_label->Text( ' Imu (camera IMU)' );
  }
  Acc16PCalibrationHalt();
  Acc16PCalibrationCdDataMatrixClear();
  $w_Acc16PCalibration->acc16pcal_OK->Disable();
  Acc16PCalibrationSetCalibration( '', '', '', '', '', '' );
  $w_Acc16PCalibration->acc16pcal_Point1_button->Disable();
  $w_Acc16PCalibration->acc16pcal_Point2_button->Disable();
  $w_Acc16PCalibration->acc16pcal_Point3_button->Disable();
  $w_Acc16PCalibration->acc16pcal_Point4_button->Disable();
  $w_Acc16PCalibration->acc16pcal_Point5_button->Disable();
  $w_Acc16PCalibration->acc16pcal_Point6_button->Disable();
  Acc16PCalibrationSetPoint1( '---', '---', '---' );
  Acc16PCalibrationSetPoint2( '---', '---', '---' );
  Acc16PCalibrationSetPoint3( '---', '---', '---' );
  Acc16PCalibrationSetPoint4( '---', '---', '---' );
  Acc16PCalibrationSetPoint5( '---', '---', '---' );
  Acc16PCalibrationSetPoint6( '---', '---', '---' );
  $w_Acc16PCalibration->acc16pcal_SaveToFile->Disable();
  $w_Acc16PCalibration->acc16pcal_Point1_inRangle->Hide();
  $w_Acc16PCalibration->acc16pcal_Point2_inRangle->Hide();
  $w_Acc16PCalibration->acc16pcal_Point3_inRangle->Hide();
  $w_Acc16PCalibration->acc16pcal_Point4_inRangle->Hide();
  $w_Acc16PCalibration->acc16pcal_Point5_inRangle->Hide();
  $w_Acc16PCalibration->acc16pcal_Point6_inRangle->Hide();
  $w_Acc16PCalibration->acc16pcal_SaveToFile->Hide();
  Acc16PCalibrationHandleWhichPointsToShow();
  $w_Acc16PCalibration->Show();
  if( $f_Tab{calibrateacc}->caac_StoreInEEprom->IsEnabled() ){ Acc16PCalibrationRun(); } #let it auto start when the connection was probably confirmed before
}

sub Acc16PCalibrationStart{
  if( $Acc16PCalibration_IsRunning ){ Acc16PCalibrationHalt(); }else{ Acc16PCalibrationRun(); }
  return 1;
}

sub Acc16PCalibrationRun{
  if( not OpenPort() ){ ClosePort(); $Acc16PCalibration_IsRunning= 0; return 1; }
#  my ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Start calibration run... Please wait!' );
#  if( $ret==100 ){ return 0; }
#  if( $ret==101 ){ ExecuteFooter($ret); $Acc1PCalibration_IsRunning= 0; return 1; }
#  if( $ret==102 ){
#    TextOut( "\r\n"."Start calibration run... ABORTED!\r\n".$Error102Str );
#    ExecuteFooter($ret); $Acc1PCalibration_IsRunning= 0; return 1;
#  }
#  TextOut( 'Start calibration run... Please wait!' );
  $w_Acc16PCalibration->acc16pcal_Start->Text( 'Stop' );
  $w_Acc16PCalibration->acc16pcal_Point1_button->Disable();
  $Acc16PCalibration_IsRunning= 1;
}

sub Acc16PCalibrationHalt{
  ClosePort();
  $w_Acc16PCalibration->acc16pcal_Start->Text( 'Start' );
  $w_Acc16PCalibration->acc16pcal_Point1_button->Disable();
  $Acc16PCalibration_IsRunning= 0;
}


sub Acc16PCalibrationSetPoint1{
  $w_Acc16PCalibration->acc16pcal_Point1_ax_accepted->Text( shift );
  $w_Acc16PCalibration->acc16pcal_Point1_ay_accepted->Text( shift );
  $w_Acc16PCalibration->acc16pcal_Point1_az_accepted->Text( shift );
}
sub Acc16PCalibrationSetPoint2{
  $w_Acc16PCalibration->acc16pcal_Point2_ax_accepted->Text( shift );
  $w_Acc16PCalibration->acc16pcal_Point2_ay_accepted->Text( shift );
  $w_Acc16PCalibration->acc16pcal_Point2_az_accepted->Text( shift );
}
sub Acc16PCalibrationSetPoint3{
  $w_Acc16PCalibration->acc16pcal_Point3_ax_accepted->Text( shift );
  $w_Acc16PCalibration->acc16pcal_Point3_ay_accepted->Text( shift );
  $w_Acc16PCalibration->acc16pcal_Point3_az_accepted->Text( shift );
}
sub Acc16PCalibrationSetPoint4{
  $w_Acc16PCalibration->acc16pcal_Point4_ax_accepted->Text( shift );
  $w_Acc16PCalibration->acc16pcal_Point4_ay_accepted->Text( shift );
  $w_Acc16PCalibration->acc16pcal_Point4_az_accepted->Text( shift );
}
sub Acc16PCalibrationSetPoint5{
  $w_Acc16PCalibration->acc16pcal_Point5_ax_accepted->Text( shift );
  $w_Acc16PCalibration->acc16pcal_Point5_ay_accepted->Text( shift );
  $w_Acc16PCalibration->acc16pcal_Point5_az_accepted->Text( shift );
}
sub Acc16PCalibrationSetPoint6{
  $w_Acc16PCalibration->acc16pcal_Point6_ax_accepted->Text( shift );
  $w_Acc16PCalibration->acc16pcal_Point6_ay_accepted->Text( shift );
  $w_Acc16PCalibration->acc16pcal_Point6_az_accepted->Text( shift );
}


sub Acc16PCalibrationSetCalibration{
  $w_Acc16PCalibration->acc16pcal_AccXZero->Text( shift );
  $w_Acc16PCalibration->acc16pcal_AccYZero->Text( shift );
  $w_Acc16PCalibration->acc16pcal_AccZZero->Text( shift );
  $w_Acc16PCalibration->acc16pcal_AccXScale->Text( shift );
  $w_Acc16PCalibration->acc16pcal_AccYScale->Text( shift );
  $w_Acc16PCalibration->acc16pcal_AccZScale->Text( shift );
}

sub Acc16PCalibrationCalc1PointCalibration{
  my $ax_scale = $AccGravityConst;
  my $ay_scale = $AccGravityConst;
  my $az_scale = $AccGravityConst;
  my $ax_zero = $w_Acc16PCalibration->acc16pcal_Point1_ax_accepted->Text();
  my $ay_zero = $w_Acc16PCalibration->acc16pcal_Point1_ay_accepted->Text();
  my $az_zero = $w_Acc16PCalibration->acc16pcal_Point1_az_accepted->Text();
  if( $ax_zero >  0.9*$AccGravityConst ){ $ax_zero -= $AccGravityConst; }
  if( $ax_zero < -0.9*$AccGravityConst ){ $ax_zero += $AccGravityConst; }
  if( $ay_zero >  0.9*$AccGravityConst ){ $ay_zero -= $AccGravityConst; }
  if( $ay_zero < -0.9*$AccGravityConst ){ $ay_zero += $AccGravityConst; }
  if( $az_zero >  0.9*$AccGravityConst ){ $az_zero -= $AccGravityConst; }
  if( $az_zero < -0.9*$AccGravityConst ){ $az_zero += $AccGravityConst; }

  Acc16PCalibrationSetCalibration( $ax_zero, $ay_zero, $az_zero, $ax_scale, $ay_scale, $az_scale );
  $w_Acc16PCalibration->acc16pcal_OK->Enable();
}


sub Acc16PCalibrationCheckIf6PointsOk{
  if( $w_Acc16PCalibration->acc16pcal_Point1_az_accepted->Text() eq '---' ){ return 0; }
  if( $w_Acc16PCalibration->acc16pcal_Point2_az_accepted->Text() eq '---' ){ return 0; }
  if( $w_Acc16PCalibration->acc16pcal_Point3_ax_accepted->Text() eq '---' ){ return 0; }
  if( $w_Acc16PCalibration->acc16pcal_Point4_ax_accepted->Text() eq '---' ){ return 0; }
  if( $w_Acc16PCalibration->acc16pcal_Point5_ay_accepted->Text() eq '---' ){ return 0; }
  if( $w_Acc16PCalibration->acc16pcal_Point6_ay_accepted->Text() eq '---' ){ return 0; }
  return 1;
}


sub Acc16PCalibrationCalc6PointCalibration{  ####CHECK IF ALL POINTS ARE OK!
  if( not Acc16PCalibrationCheckIf6PointsOk() ){ return; }

  my $az_p = $w_Acc16PCalibration->acc16pcal_Point1_az_accepted->Text();
  my $az_m = $w_Acc16PCalibration->acc16pcal_Point2_az_accepted->Text();
  my $ax_p = $w_Acc16PCalibration->acc16pcal_Point3_ax_accepted->Text();
  my $ax_m = $w_Acc16PCalibration->acc16pcal_Point4_ax_accepted->Text();
  my $ay_p = $w_Acc16PCalibration->acc16pcal_Point5_ay_accepted->Text();
  my $ay_m = $w_Acc16PCalibration->acc16pcal_Point6_ay_accepted->Text();

  my $ax_scale = sprintf( "%.0f", ($ax_p - $ax_m)/2.0 );
  my $ay_scale = sprintf( "%.0f", ($ay_p - $ay_m)/2.0 );
  my $az_scale = sprintf( "%.0f", ($az_p - $az_m)/2.0 );
  my $ax_zero  = sprintf( "%.0f", ($ax_p + $ax_m)/2.0 );
  my $ay_zero  = sprintf( "%.0f", ($ay_p + $ay_m)/2.0 );
  my $az_zero  = sprintf( "%.0f", ($az_p + $az_m)/2.0 );

  Acc16PCalibrationSetCalibration( $ax_zero, $ay_zero, $az_zero, $ax_scale, $ay_scale, $az_scale );
  $w_Acc16PCalibration->acc16pcal_OK->Enable();
  $w_Acc16PCalibration->acc16pcal_SaveToFile->Enable();

  my $quality = 0;
  #Z
  $quality+= sqr( $w_Acc16PCalibration->acc16pcal_Point3_az_accepted->Text() - $az_zero );
  $quality+= sqr( $w_Acc16PCalibration->acc16pcal_Point4_az_accepted->Text() - $az_zero );
  $quality+= sqr( $w_Acc16PCalibration->acc16pcal_Point5_az_accepted->Text() - $az_zero );
  $quality+= sqr( $w_Acc16PCalibration->acc16pcal_Point6_az_accepted->Text() - $az_zero );
  #X
  $quality+= sqr( $w_Acc16PCalibration->acc16pcal_Point1_ax_accepted->Text() - $ax_zero );
  $quality+= sqr( $w_Acc16PCalibration->acc16pcal_Point2_ax_accepted->Text() - $ax_zero );
  $quality+= sqr( $w_Acc16PCalibration->acc16pcal_Point5_ax_accepted->Text() - $ax_zero );
  $quality+= sqr( $w_Acc16PCalibration->acc16pcal_Point6_ax_accepted->Text() - $ax_zero );
  #Y
  $quality+= sqr( $w_Acc16PCalibration->acc16pcal_Point1_ay_accepted->Text() - $ay_zero );
  $quality+= sqr( $w_Acc16PCalibration->acc16pcal_Point2_ay_accepted->Text() - $ay_zero );
  $quality+= sqr( $w_Acc16PCalibration->acc16pcal_Point3_ay_accepted->Text() - $ay_zero );
  $quality+= sqr( $w_Acc16PCalibration->acc16pcal_Point4_ay_accepted->Text() - $ay_zero );

  $quality= sqrt( $quality/12 );
  $w_Acc16PCalibration->acc16pcal_Quality_label->Text("quality: ".sprintf("%.0f",$quality)."        ");
}


sub Acc16PCalibrationCdDataMatrixClear{
  for(my $j=0; $j<512; $j++ ){
    for(my $i=0; $i<512; $i++ ){ $CdDataMatrix[$j][$i]= 0; }
  }
}


sub Acc16PCalibrationDoTimer{
  if( not $Acc16PCalibration_IsRunning){ return 1; }
  #read data frame
  my $s= ExecuteCmd( 'Cd', $CMD_Cd_PARAMETER_ZAHL*2 );
  if( substr($s,length($s)-1,1) ne 'o' ){ return 1; }
  my @CdData = unpack( "v$CMD_Cd_PARAMETER_ZAHL", $s );
  for(my $n=0;$n<$CMD_Cd_PARAMETER_ZAHL;$n++){
    if( substr($CdDataFormatStr,$n,1) eq 's' ){ if( $CdData[$n]>32768 ){ $CdData[$n]-=65536; }  }
  }
  #Imu1: Gx, Gy, Gz
  $CdDataMatrix[$CdDataGx_i][$CdDataPos]= $CdData[$CdDataGx_p];
  $CdDataMatrix[$CdDataGy_i][$CdDataPos]= $CdData[$CdDataGy_p];
  $CdDataMatrix[$CdDataGz_i][$CdDataPos]= $CdData[$CdDataGz_p];
  #Imu1: Ax, Ay, Az
  $CdDataMatrix[$CdDataAx_i][$CdDataPos]= $CdData[$CdDataAx_p];
  $CdDataMatrix[$CdDataAy_i][$CdDataPos]= $CdData[$CdDataAy_p];
  $CdDataMatrix[$CdDataAz_i][$CdDataPos]= $CdData[$CdDataAz_p];
  #Imu1: Temp
  $CdDataMatrix[$CdDataTemp_i][$CdDataPos]= $CdData[$CdDataTemp_p];
  #Imu2: Gx, Gy, Gz
  $CdDataMatrix[$CdDataGx2_i][$CdDataPos]= $CdData[$CdDataGx2_p];
  $CdDataMatrix[$CdDataGy2_i][$CdDataPos]= $CdData[$CdDataGy2_p];
  $CdDataMatrix[$CdDataGz2_i][$CdDataPos]= $CdData[$CdDataGz2_p];
  #Imu2: Ax, Ay, Az
  $CdDataMatrix[$CdDataAx2_i][$CdDataPos]= $CdData[$CdDataAx2_p];
  $CdDataMatrix[$CdDataAy2_i][$CdDataPos]= $CdData[$CdDataAy2_p];
  $CdDataMatrix[$CdDataAz2_i][$CdDataPos]= $CdData[$CdDataAz2_p];
  #Imu2: Temp
  $CdDataMatrix[$CdDataTemp2_i][$CdDataPos]= $CdData[$CdDataTemp2_p];

  #display
  $CdDataTimeCounter++;
  if( $CdDataTimeCounter>=10 ){ $CdDataTimeCounter= 0; }
  if( $CdDataTimeCounter==0 ){ #slows down update
    if( $Acc16PCalibration_ImuNr!=1 ){ #IMU1
      $w_Acc16PCalibration->acc16pcal_ax->Text( $CdData[$CdDataAx_p] );
      $w_Acc16PCalibration->acc16pcal_ay->Text( $CdData[$CdDataAy_p] );
      $w_Acc16PCalibration->acc16pcal_az->Text( $CdData[$CdDataAz_p] );
      $w_Acc16PCalibration->acc16pcal_temp->Text( sprintf("%.2f�", $CdData[$CdDataTemp_p]/340.0+36.53) );#$CdData[$CdDataTemp_p] );
    }else{ #IMU2
      $w_Acc16PCalibration->acc16pcal_ax->Text( $CdData[$CdDataAx2_p] );
      $w_Acc16PCalibration->acc16pcal_ay->Text( $CdData[$CdDataAy2_p] );
      $w_Acc16PCalibration->acc16pcal_az->Text( $CdData[$CdDataAz2_p] );
      $w_Acc16PCalibration->acc16pcal_temp->Text( sprintf("%.2f�", $CdData[$CdDataTemp2_p]/340.0+36.53) );#$CdData[$CdDataTemp_p] );
    }
  }

  $CdDataPos++;
  if( $CdDataPos>=256 ){ $CdDataPos= 0; }

  my $ax_av= 0; my $ax_sig= 0;
  my $ay_av= 0; my $ay_sig= 0;
  my $az_av= 0; my $az_sig= 0;
  my $temp_av= 0;
  for(my $i=0; $i<256; $i++ ){
    if( $Acc16PCalibration_ImuNr!=1 ){ #IMU1
      $ax_av += $CdDataMatrix[$CdDataAx_i][$i];
      $ay_av += $CdDataMatrix[$CdDataAy_i][$i];
      $az_av += $CdDataMatrix[$CdDataAz_i][$i];
      $temp_av += $CdDataMatrix[$CdDataTemp_i][$i];
    }else{ #IMU2
      $ax_av += $CdDataMatrix[$CdDataAx2_i][$i];
      $ay_av += $CdDataMatrix[$CdDataAy2_i][$i];
      $az_av += $CdDataMatrix[$CdDataAz2_i][$i];
      $temp_av += $CdDataMatrix[$CdDataTemp2_i][$i];
    }
  }
  $ax_av = sprintf( "%.0f", $ax_av / 256.0 );
  $ay_av = sprintf( "%.0f", $ay_av / 256.0 );
  $az_av = sprintf( "%.0f", $az_av / 256.0 );
  $temp_av = sprintf( "%.2f", $temp_av / 256.0 );
  for(my $i=0; $i<256; $i++ ){
    if( $Acc16PCalibration_ImuNr!=1 ){ #IMU1
      $ax_sig += abs( $CdDataMatrix[$CdDataAx_i][$i]-$ax_av );
      $ay_sig += abs( $CdDataMatrix[$CdDataAy_i][$i]-$ay_av );
      $az_sig += abs( $CdDataMatrix[$CdDataAz_i][$i]-$az_av );
    }else{ #IMU2
      $ax_sig += abs( $CdDataMatrix[$CdDataAx2_i][$i]-$ax_av );
      $ay_sig += abs( $CdDataMatrix[$CdDataAy2_i][$i]-$ay_av );
      $az_sig += abs( $CdDataMatrix[$CdDataAz2_i][$i]-$az_av );
    }
  }
  $w_Acc16PCalibration->acc16pcal_ax_av->Text( $ax_av );
  $w_Acc16PCalibration->acc16pcal_ax_sig->Text( sprintf( "%.0f", $ax_sig/256) );
  $w_Acc16PCalibration->acc16pcal_ay_av->Text( $ay_av );
  $w_Acc16PCalibration->acc16pcal_ay_sig->Text( sprintf( "%.0f", $ay_sig/256) );
  $w_Acc16PCalibration->acc16pcal_az_av->Text( $az_av );
  $w_Acc16PCalibration->acc16pcal_az_sig->Text( sprintf( "%.0f", $az_sig/256) );
  $w_Acc16PCalibration->acc16pcal_temp_av->Text( sprintf("%.2f�", $temp_av/340.0+36.53) );

  if( $Acc16PCalibration_Is1Point==1 ){
    if(( abs($ax_av) > 0.85*$AccGravityConst )or
       ( abs($ay_av) > 0.85*$AccGravityConst )or
       ( abs($az_av) > 0.75*$AccGravityConst )   ){
      $w_Acc16PCalibration->acc16pcal_Point1_button->Enable();
      $w_Acc16PCalibration->acc16pcal_Point1_inRangle->Show();
    }else{
      $w_Acc16PCalibration->acc16pcal_Point1_button->Disable();
      $w_Acc16PCalibration->acc16pcal_Point1_inRangle->Hide();
    }
  }else{
    if( $az_av > 0.75*$AccGravityConst ){
      $w_Acc16PCalibration->acc16pcal_Point1_button->Enable();
      $w_Acc16PCalibration->acc16pcal_Point1_inRangle->Show();
    }else{
      $w_Acc16PCalibration->acc16pcal_Point1_button->Disable();
      $w_Acc16PCalibration->acc16pcal_Point1_inRangle->Hide();
    }
    if( $az_av <-0.75*$AccGravityConst ){
      $w_Acc16PCalibration->acc16pcal_Point2_button->Enable();
      $w_Acc16PCalibration->acc16pcal_Point2_inRangle->Show();
    }else{
      $w_Acc16PCalibration->acc16pcal_Point2_button->Disable();
      $w_Acc16PCalibration->acc16pcal_Point2_inRangle->Hide();
    }
    if( $ax_av > 0.85*$AccGravityConst ){
      $w_Acc16PCalibration->acc16pcal_Point3_button->Enable();
      $w_Acc16PCalibration->acc16pcal_Point3_inRangle->Show();
    }else{
      $w_Acc16PCalibration->acc16pcal_Point3_button->Disable();
      $w_Acc16PCalibration->acc16pcal_Point3_inRangle->Hide();
    }
    if( $ax_av < -0.85*$AccGravityConst ){
      $w_Acc16PCalibration->acc16pcal_Point4_button->Enable();
      $w_Acc16PCalibration->acc16pcal_Point4_inRangle->Show();
    }else{
      $w_Acc16PCalibration->acc16pcal_Point4_button->Disable();
      $w_Acc16PCalibration->acc16pcal_Point4_inRangle->Hide();
    }
    if( $ay_av > 0.85*$AccGravityConst ){
      $w_Acc16PCalibration->acc16pcal_Point5_button->Enable();
      $w_Acc16PCalibration->acc16pcal_Point5_inRangle->Show();
    }else{
      $w_Acc16PCalibration->acc16pcal_Point5_button->Disable();
      $w_Acc16PCalibration->acc16pcal_Point5_inRangle->Hide();
    }
    if( $ay_av < -0.85*$AccGravityConst ){
      $w_Acc16PCalibration->acc16pcal_Point6_button->Enable();
      $w_Acc16PCalibration->acc16pcal_Point6_inRangle->Show();
    }else{
      $w_Acc16PCalibration->acc16pcal_Point6_button->Disable();
      $w_Acc16PCalibration->acc16pcal_Point6_inRangle->Hide();
    }
  }
  1;
}



#similar to sub ExecuteSaveCalibrationData()
sub Acc16PCalibrationSave6PointCalibrationData{
  my $file= Win32::GUI::GetSaveFileName( -owner=> $w_Main,
    -title=> 'Save Calibration Data to File',
    -nochangedir=> 1,
    -directory=> $SettingsFile_lastdir, #".\\",
    -defaultextension=> '.cal',
    -filter=> ['*.cal'=>'*.cal','All files' => '*.*'],
    -pathmustexist=> 1,
    -overwriteprompt=> 1,
    -noreadonlyreturn => 1,
    -explorer=>0,
  );
  if( $file ){
    if( !open(F,">$file") ){ $w_Main->MessageBox("Some error occured, sorry",'ERROR'); return; }
    print F 'IMUNAME: '.NameExtStr($file)."\n";
    print F 'IMUTYPE: '.$CalibrationDataRecord{imutype}."\n"; #MPU6050
    print F 'IMUSETTINGS: '.$CalibrationDataRecord{imusettings}."\n"; #get from above
    print F 'RECORD#1'."\n";
    print F 'AXZERO: '.$w_Acc16PCalibration->acc16pcal_AccXZero->Text()."\n";
    print F 'AYZERO: '.$w_Acc16PCalibration->acc16pcal_AccYZero->Text()."\n";
    print F 'AZZERO: '.$w_Acc16PCalibration->acc16pcal_AccZZero->Text()."\n";
    print F 'AXSCALE: '.$w_Acc16PCalibration->acc16pcal_AccXScale->Text()."\n";
    print F 'AYSCALE: '.$w_Acc16PCalibration->acc16pcal_AccYScale->Text()."\n";
    print F 'AZSCALE: '.$w_Acc16PCalibration->acc16pcal_AccZScale->Text()."\n";
    print F 'CALIBRATIONMETHOD: 6 point'."\n";
    print F 'TEMPERATURE: '.$w_Acc16PCalibration->acc16pcal_temp_av->Text()."\n";
    print F 'RAW: '."\n";
    print F '1. (+Z):  ';
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point1_ax_accepted->Text()).", ";
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point1_ay_accepted->Text()).", ";
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point1_az_accepted->Text())."\n";
    print F '2. (-Z):  ';
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point2_ax_accepted->Text()).", ";
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point2_ay_accepted->Text()).", ";
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point2_az_accepted->Text())."\n";
    print F '3. (+X):  ';
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point3_ax_accepted->Text()).", ";
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point3_ay_accepted->Text()).", ";
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point3_az_accepted->Text())."\n";
    print F '4. (-X):  ';
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point4_ax_accepted->Text()).", ";
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point4_ay_accepted->Text()).", ";
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point4_az_accepted->Text())."\n";
    print F '5. (+Y):  ';
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point5_ax_accepted->Text()).", ";
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point5_ay_accepted->Text()).", ";
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point5_az_accepted->Text())."\n";
    print F '6. (-Y):  ';
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point6_ax_accepted->Text()).", ";
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point6_ay_accepted->Text()).", ";
    print F sprintf( "% 6.0f", $w_Acc16PCalibration->acc16pcal_Point6_az_accepted->Text())."\n";
    print F 'quality:  '.$w_Acc16PCalibration->acc16pcal_Quality_label->Text();
    close(F);
  }elsif( Win32::GUI::CommDlgExtendedError() ){$w_Main->MessageBox("Some error occured, sorry",'ERROR');}
  1;
}









#-----------------------------------------------------------------------------#
###############################################################################
###############################################################################
# ALIGN YAW AXIS Tool Window
###############################################################################
###############################################################################
#-----------------------------------------------------------------------------#
my $AlignYawAdr1= 0;  #Rc Yaw
my $AlignYawRes1= 'c';
my $AlignYawAdr2= 0;  #Rc Yaw Mode
my $AlignYawRes2= 'c';
my $AlignYawAdr3= 0;  #Rc Yaw Offset
my $AlignYawRes3= 'c';
my $AlignYawAdr4= 0;  #Pitch Startup
my $AlignYawRes4= 'c';
my $AlignYawAdr5= 0;  #Roll Startup
my $AlignYawRes5= 'c';

my $AlignYawOffset= 0;

my $AlignYawBackgroundColor= [96,96,96];

$xsize= 450;
$ysize= 300; #470;

my $w_AlignYaw= Win32::GUI::DialogBox->new( -name=> 'alignyaw_Window', -parent => $w_Main, -font=> $StdWinFont,
  -text=> "Align Yaw Axis Tool",
  -size=> [$xsize,$ysize],
  -helpbox => 0,
  -background=>$AlignYawBackgroundColor,
);
$w_AlignYaw->SetIcon($Icon);

sub t_AlignYawAxis_Click{ AlignYawShowAndRead(); 0; }
sub alignyaw_Window_Terminate{ AlignYawUndo(); $w_AlignYaw->Hide(); 0; }

$xpos= 20;
$ypos= 20;
$w_AlignYaw->AddLabel( -name=> 'alignyaw_Text1_label', -font=> $StdWinFont,
  -text=> "With this tool you can align the yaw axis to point forward.",
  -pos=> [$xpos,$ypos], -width=> 420,  -height=>30,
  -background=>$AlignYawBackgroundColor, -foreground=> [255,255,255],
);
$ypos+= 30;
$w_AlignYaw->AddLabel( -name=> 'alignyaw_Text1b_label', -font=> $StdWinFont,
  -text=> "IMPORTANT:
The gimbal must be fully operational, and in NORMAL state (solid green led).",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>3*13+10, -width=> 420,
  -background=>$AlignYawBackgroundColor, -foreground=> [255,255,255],
);

$ypos+= 35 + 1*13;
$w_AlignYaw->AddLabel( -name=> 'alignyaw_Text3_label', -font=> $StdWinFont,
  -text=> "Adjust the yaw axis using these buttons:",
  -pos=> [$xpos,$ypos], -width=> 250,  -height=>30,
  -background=>$AlignYawBackgroundColor, -foreground=> [255,255,255],
);

$xpos = $xsize/2;
$ypos+= 25;
$w_AlignYaw->AddButton( -name=> 'alignyaw_Left3', -font=> $StdWinFont,
  -text=> '<<<', -pos=> [$xpos-15 -3*30-20,$ypos], -width=> 30,
  -onClick => sub{ $AlignYawOffset += 50; AlignYawMove($AlignYawOffset); 1; }, #-5�
);
$w_AlignYaw->AddButton( -name=> 'alignyaw_Left2', -font=> $StdWinFont,
  -text=> '<<', -pos=> [$xpos-15 -2*30-15,$ypos], -width=> 30,
  -onClick => sub{ $AlignYawOffset += 10; AlignYawMove($AlignYawOffset); 1; }, #-1�
);
$w_AlignYaw->AddButton( -name=> 'alignyaw_Left', -font=> $StdWinFont,
  -text=> '<', -pos=> [$xpos-15 -1*30-10,$ypos], -width=>30,
  -onClick => sub{ $AlignYawOffset += 1; AlignYawMove($AlignYawOffset); 1; }, #-0.1�
);
$w_AlignYaw->AddButton( -name=> 'alignyaw_Right', -font=> $StdWinFont,
  -text=> '>', -pos=> [$xpos-15 +1*30+10,$ypos], -width=> 30,
  -onClick => sub{ $AlignYawOffset -= 1; AlignYawMove($AlignYawOffset); 1; }, #+0.1�
);
$w_AlignYaw->AddButton( -name=> 'alignyaw_Right2', -font=> $StdWinFont,
  -text=> '>>', -pos=> [$xpos-15 +2*30+15,$ypos], -width=> 30,
  -onClick => sub{ $AlignYawOffset -= 10; AlignYawMove($AlignYawOffset); 1; }, #+1�
);
$w_AlignYaw->AddButton( -name=> 'alignyaw_Right3', -font=> $StdWinFont,
  -text=> '>>>', -pos=> [$xpos-15 +3*30+20,$ypos], -width=> 30,
  -onClick => sub{ $AlignYawOffset -= 50; AlignYawMove($AlignYawOffset); 1; }, #+5�
);

$w_AlignYaw->AddLabel( -name=> 'alignyaw_Offset_label', -font=> $StdWinFont,
  -text=> '0.0�', -pos=> [$xpos-20,$ypos+3], -width=> 40, -align=> 'center',
  -background=>$AlignYawBackgroundColor, -foreground=> [255,255,255],
);



$xpos= 20;
$ypos+= 35 + 3*13 -25;
$w_AlignYaw->AddLabel( -name=> 'alignyaw_Text4_label', -font=> $StdWinFont,
  -text=> "When the yaw axis is aligned, press OK; or press Cancel to abort.",
  -pos=> [$xpos,$ypos], -width=> 500,  -height=>30,
  -background=>$AlignYawBackgroundColor, -foreground=> [255,255,255],
);


$xpos= 20;
$ypos+= 35;
$w_AlignYaw->AddButton( -name=> 'alignyaw_OK', -font=> $StdWinFont,
  -text=> 'OK', -pos=> [$xsize/2-40,$ypos], -width=> 80,
);

$w_AlignYaw->AddButton( -name=> 'alignyaw_Cancel', -font=> $StdWinFont,
  -text=> 'Cancel', -pos=> [$xsize/2-40,$ypos+30], -width=> 80,
  -onClick => sub{ AlignYawUndo(); $w_AlignYaw->Hide(); 0; },
);


sub AlignYawShowAndRead{
#  if( $DataDisplay_IsRunning ){ TextOut("\r\nStop DataDisplay before calling AlignYawAxisTool!\r\n"); }
  TextOut( "\r\n".'Align Yaw Axis Tool... Please wait!' );
  TextOut( "\r\n".'Reading... ' );
  if( not $w_Main->m_Write->IsEnabled() ){
    TextOut( "\r\n".'Align Yaw Axis Tool... ABORTED!'."\r\n".'Please do first a read to get controller settings!'."\r\n" );
    return;
  }
  if( not defined $NameToOptionHash{ 'Rc Yaw' } ){ return; }
  if( not defined $NameToOptionHash{ 'Rc Yaw Mode' } ){ return; }
  if( not defined $NameToOptionHash{ 'Rc Yaw Offset' } ){ return; }
  if( not defined $NameToOptionHash{ 'Pitch Startup Motor Pos' } ){ return; }
  if( not defined $NameToOptionHash{ 'Roll Startup Motor Pos' } ){ return; }
  if( not defined $NameToOptionHash{ 'Yaw Startup Motor Pos' } ){ return; }
  if( $DataDisplay_IsRunning ){ DataDisplayStart(); }
  if( not OpenPort() ){ TextOut("\r\n"."Port XXX FX�pd!"."\r\n"); return; }
  my ($x, $y) = ($w_Main->GetWindowRect())[0..1];
  $w_AlignYaw->Move($x+150,$y+100);
  $w_AlignYaw->Show();
  #get Rc Yaw
  $AlignYawAdr1= $NameToOptionHash{'Rc Yaw'}->{adr};
  TextOut( $AlignYawAdr1.";" );
  $AlignYawRes1= SendMavlinkCmd2( '03'. UCharToHexstr($AlignYawAdr1).'00', 8+2*2 );
#TextOut( $AlignYawRes1."!" );TextOut( substr($AlignYawRes1,12,8)."!!" );
  #get Rc Yaw Mode
  $AlignYawAdr2= $NameToOptionHash{'Rc Yaw Mode'}->{adr};
  TextOut( $AlignYawAdr2.";" );
  $AlignYawRes2= SendMavlinkCmd2( '03'. UCharToHexstr($AlignYawAdr2).'00', 8+2*2 );
#TextOut( $AlignYawRes2."!" );TextOut( substr($AlignYawRes2,12,8)."!!" );
  #get Rc Yaw Offset
  $AlignYawAdr3= $NameToOptionHash{'Rc Yaw Offset'}->{adr};
  TextOut( $AlignYawAdr3.";" );
  $AlignYawRes3= SendMavlinkCmd2( '03'. UCharToHexstr($AlignYawAdr3).'00', 8+2*2 );
#TextOut( $AlignYawRes3."!" );TextOut( substr($AlignYawRes3,12,8)."!!" );
#  $res3= 'c';
  #get Pitch Startup Motor Pos
  $AlignYawAdr4= $NameToOptionHash{'Pitch Startup Motor Pos'}->{adr};
  TextOut( $AlignYawAdr4.";" );
  $AlignYawRes4= SendMavlinkCmd2( '03'. UCharToHexstr($AlignYawAdr4).'00', 8+2*2 );
  #get Roll Startup Motor Pos
  $AlignYawAdr5= $NameToOptionHash{'Roll Startup Motor Pos'}->{adr};
  TextOut( $AlignYawAdr5.";" );
  $AlignYawRes5= SendMavlinkCmd2( '03'. UCharToHexstr($AlignYawAdr5).'00', 8+2*2 );
  #check
  if( $AlignYawRes1 eq 't' or $AlignYawRes1 eq 'c' or
      $AlignYawRes2 eq 't' or $AlignYawRes2 eq 'c' or
      $AlignYawRes3 eq 't' or $AlignYawRes3 eq 'c' or
      $AlignYawRes4 eq 't' or $AlignYawRes4 eq 'c' or
      $AlignYawRes5 eq 't' or $AlignYawRes5 eq 'c'     ){
    TextOut( "\r\n".'Align Yaw Axis Tool... ABORTED!'."\r\n" );
    $w_AlignYaw->Hide();
    return;
  }
  #set Rc Yaw
  SendMavlinkCmd2( '04'. UCharToHexstr($AlignYawAdr1).'00'.'0000' );
  #set Rc Yaw Mode
  SendMavlinkCmd2( '04'. UCharToHexstr($AlignYawAdr2).'00'.'0000' );
  #set Rc Yaw Offset
  SendMavlinkCmd2( '04'. UCharToHexstr($AlignYawAdr3).'00'.'0000' );
  $AlignYawOffset= 0; #set to zero to start with
  $w_AlignYaw->alignyaw_Offset_label->Text( '0.0�' );
  TextOut( ' ok'."\r\n" );
  ClosePort();
}

sub AlignYawUndowoOpenClose{
  TextOut( 'Undo... ' );
  #undo: set Rc Yaw
  SendMavlinkCmd2( '04'. substr($AlignYawRes1,12,8) );
  #undo: set Rc Yaw Mode
  SendMavlinkCmd2( '04'. substr($AlignYawRes2,12,8) );
  #undo: set Rc Yaw Offset
  SendMavlinkCmd2( '04'. substr($AlignYawRes3,12,8) );
  #undo: set Pitch Startup Motor Pos
  SendMavlinkCmd2( '04'. substr($AlignYawRes4,12,8) );
  #undo: set Pitch Startup Motor Pos
  SendMavlinkCmd2( '04'. substr($AlignYawRes5,12,8) );
  TextOut( ' ok'."\r\n" );
  TextOut( 'Align Yaw Axis Tool... DONE!'."\r\n" );
}

sub AlignYawUndo{
  if( not OpenPort() ){ TextOut("\r\n"."Port XXX FX�pd!"."\r\n"); return; }
  AlignYawUndowoOpenClose();
  ClosePort();
}


sub AlignYawMove{
  my $v= shift;
  $w_AlignYaw->alignyaw_Offset_label->Text( sprintf("% .1f�", $v/10.0) );
  if( $v<0 ){ $v = $v+65536; }
  $v= UIntToHexstr($v);
  $v= substr($v,2,2).substr($v,0,2);
  TextOut( "Move ..." );
  if( not OpenPort() ){ TextOut("\r\n"."Port XXX FX�pd!"."\r\n"); return; }
  SendMavlinkCmd2( '04'. UCharToHexstr($AlignYawAdr3).'00'.$v );
  ClosePort();
  TextOut( " ok"."\r\n" );
}


sub SendMavlinkCmd2{
  my $msg= shift; #command + payload
  my $doread= shift; if( not defined $doread ){ $doread=9; } #this is the default CMD_ACK
  my $msglen= UCharToHexstr( length($msg)/2 - 1 );
#TextOut( "!$msglen!" );
  my $cmd= 'FE'. $msglen .'00'.'52'.'43'. $msg . '33'.'34';
###  if( not OpenPort() ){ TextOut("\r\n"."Port XXX FX�pd!"."\r\n"); return; }
  $p_Serial->owwrite_overlapped_undef( HexstrToStr($cmd) );
  my $count= 0; my $result= '';
  my $tmo= $p_Serial->get_tick_count() + 20*$ExecuteCmdTimeOut; #timeout in 100 ms
  do{
    if( $p_Serial->get_tick_count() > $tmo  ){ $result='t'; goto EXIT; }
    my ($i, $s) = $p_Serial->owread_overlapped(1);
    $result.= $s;
#TextOut( StrToHexstr($s)."!" );
    $count+= $i;
  }while( $count<$doread ); # xFE x01 x00 x47='G' x43='C' x96=150 x??=ack crc-low crc-high
#TextOut( StrToHexstr($result)."!" );
  my $crc=0;
  #check CRC (uses MAVLINK's x25 checksum)
  $crc= unpack( "v", substr($result,$count-2,2) );
#TextOut( " CRC:".UIntToHexstr($crc) );
  my $crc2= do_crc( substr($result,1), $count );
#TextOut( " CRC2:0x".UIntToHexstr($crc2)."!" );
  if( $crc2 != 0 ){ $result='c'; goto EXIT; }
  $result = StrToHexstr($result);
EXIT:
#TextOut( "X".$result."X" );
###  ClosePort();
  return $result;
}


sub alignyaw_OK_Click{
#  ExecuteCommandFullwoGet( 'xm', 'Get current motor directions', '' );
  if( not OpenPort() ){ TextOut("\r\n"."Port XXX FX�pd!"."\r\n"); return; }
  TextOut_( "\r\n".'xz'.'... ' );
  my $s= ExecuteCmd( 'xz' ); #  my $s= ExecuteCmd( 'Cd', $CMD_Cd_PARAMETER_ZAHL*2 );
  AlignYawUndowoOpenClose();
  #get Yaw Startup Motor Pos
  my $option= $NameToOptionHash{'Yaw Startup Motor Pos'};
  #TextOut( $AlignYawAdr5.";" );
  my $res= SendMavlinkCmd2( '03'. UCharToHexstr( $option->{adr}).'00', 8+2*2 );
  if( $res ne 't' and $res ne 'c' ){
#TextOut( "!".$res."!" );
    $res= substr($res,12+4,4);
#TextOut( "!".$res."!" );
    $res= substr($res,2,2).substr($res,0,2);
#TextOut( "!".$res."!" );
    $res= HexstrToDez($res);
#TextOut( "!".$res."!" );
    SetOptionField( $option, $res );
  }
  ClosePort();
#  ExecuteRead();
  $w_AlignYaw->Hide();
  0;
}


# Ende # ALIGN YAW AXIS Tool Window
###############################################################################






















#-----------------------------------------------------------------------------#
###############################################################################
###############################################################################
# TUNING Tool Window
###############################################################################
###############################################################################
#-----------------------------------------------------------------------------#

my $TuningToolXPos= 100;
my $TuningToolYPos= 100;

$xsize= 450;
$ysize= 470;

my $w_TuningTool= Win32::GUI::DialogBox->new( -name=> 'tt_Window',  -parent => $w_Main, -font=> $StdWinFont,
    -text=> "Tuning Tool",
    -pos=> [$TuningToolXPos,$TuningToolYPos],
    -size=> [$xsize,$ysize],
   -helpbox => 0,
);
$w_TuningTool->SetIcon($Icon);

sub tt_Window_Terminate{ $w_TuningTool->Hide(); 0; }
sub t_TuningTool_Click{ $w_TuningTool->Show(); 1; }


$xpos= 20;
$ypos= 20;




















#-----------------------------------------------------------------------------#
###############################################################################
###############################################################################
# BLUETOOTH Configuration Tool Window
###############################################################################
###############################################################################
#-----------------------------------------------------------------------------#

#my $BTConfigXPos= 100;
#my $BTConfigYPos= 100;
my $BTConfigBackgroundColor= [96,96,96];

$xsize= 450;
$ysize= 470;

#my $w_BTConfig= Win32::GUI::Window->new( -name=> 'btconfig_Window',
my $w_BTConfig= Win32::GUI::DialogBox->new( -name=> 'btconfig_Window', -parent => $w_Main, -font=> $StdWinFont,
  -text=> "BTConfigTool",
#  -pos=> [$BTConfigXPos,$BTConfigYPos],
  -size=> [$xsize,$ysize],
  -helpbox => 0,
  -background=>$BTConfigBackgroundColor,
);
$w_BTConfig->SetIcon($Icon);


$xpos= 20;
$ypos= 20;
$w_BTConfig->AddLabel( -name=> 'btconfig_Text1_label', -font=> $StdWinFont,
  -text=> "With this tool you can configure the BT module (HC06) on your STorM32-BGC board.",
  -pos=> [$xpos,$ypos], -width=> 420,  -height=>30,
  -background=>$BTConfigBackgroundColor, -foreground=> [255,255,255],
);
$ypos+= 30;
$w_BTConfig->AddLabel( -name=> 'btconfig_Text1b_label', -font=> $StdWinFont,
  -text=> "IMPORTANT:
The board MUST be connected to the PC via the USB connector.
There MUST NOT be anything connected to the UART port.
It's a good idea to press the Reset button now.",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>4*13+10, -width=> 420,
  -background=>$BTConfigBackgroundColor, -foreground=> [255,255,255],
);

$ypos+= 35 + 3*13;
$w_BTConfig->AddLabel( -name=> 'btconfig_Text3_label', -font=> $StdWinFont,
  -text=> "Select the USB COM port your board is attached to:",
  -pos=> [$xpos,$ypos], -width=> 250,  -height=>30,
  -background=>$BTConfigBackgroundColor, -foreground=> [255,255,255],
);
$xpos+= 250;
#$ypos+= 25;
$w_BTConfig->AddCombobox( -name=> 'btconfig_Port', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos-3], -size=> [140,100],
#  -dropdownlist=> 1, -vscroll=>1,
  -dropdown=> 1, -vscroll=>1,
  -onDropDown=> sub{
    ($GetComPortOK,@PortList)= GetComPorts();
    if($GetComPortOK>0){
      my $s= $_[0]->Text();
      $_[0]->Clear(); $_[0]->Add( @PortList ); $_[0]->SelectString( $s ); #$Port has COM + friendly name
      if($_[0]->SelectedItem()<0){ $_[0]->Select(0); }
    }
  }
);
$w_BTConfig->btconfig_Port->SetDroppedWidth(140);
$w_BTConfig->btconfig_Port->Add( @PortList );
if( scalar @PortList){ $w_BTConfig->btconfig_Port->SelectString( 'COM1' ); } #$Port has COM + friendly name

$xpos= 20;
$ypos+= 35;
$w_BTConfig->AddLabel( -name=> 'btconfig_Text333_label', -font=> $StdWinFont,
  -text=> "Enter the desired name of the BT module:",
  -pos=> [$xpos,$ypos],
  -background=>$BTConfigBackgroundColor, -foreground=> [255,255,255],
);
$xpos+= 250;
$w_BTConfig-> AddTextfield( -name=> 'btconfig_Name', -font=> $StdWinFont,
  -pos=> [$xpos,$ypos-3], -size=> [140,23],
);
$w_BTConfig->btconfig_Name->SetLimitText(11);
$w_BTConfig->btconfig_Name->Text('STorM32-BGC');




$xpos= 20;
$ypos+= 35;
$w_BTConfig->AddLabel( -name=> 'btconfig_Text4_label', -font=> $StdWinFont,
  -text=> "Run the auto configure sequence:
(please be patient, this takes few minutes)",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>2*13+10,
  -background=>$BTConfigBackgroundColor, -foreground=> [255,255,255],
);
$xpos+= 250;
#$ypos+= 25;
$w_BTConfig->AddButton( -name=> 'btconfig_AutoConfigure', -font=> $StdWinFont,
  -text=> 'Auto Configure', -pos=> [$xpos,$ypos-3+7], -width=> 140,
);

$xpos= 20;
$ypos+= 65;
$w_BTConfig->AddLabel( -name=> 'btconfig_Text5_label', -font=> $StdWinFont,
  -text=> "Manual configuration tool (for experts only)",
  -pos=> [$xpos,$ypos],
  -background=>$BTConfigBackgroundColor, -foreground=> [255,255,255],
);
$ypos+= 20;
$w_BTConfig->AddLabel( -name=> 'btconfig_Text5b_label', -font=> $StdWinFont,
  -text=> "command",
  -pos=> [$xpos,$ypos],
  -background=>$BTConfigBackgroundColor, -foreground=> [255,255,255],
);
$w_BTConfig->AddTextfield( -name=> 'btconfig_Cmd', -font=> $StdWinFont,
  -pos=> [$xpos+$w_BTConfig->btconfig_Text5b_label->Width()+3,$ypos-3], -size=> [$xsize-157-4+46-$w_BTConfig->btconfig_Text5b_label->Width(),23],
);
$w_BTConfig->AddButton( -name=> 'btconfig_Send', -font=> $StdWinFont,
  -text=> 'Send', -pos=> [$xsize-90,$ypos-3+2], -width=> 60,
);
$w_BTConfig->btconfig_Cmd->Text('');

$w_BTConfig-> AddTextfield( -name=> 'btconfig_RecieveText',
  -pos=> [5,$ysize-150-18+5], -size=> [$xsize-16,93+40-5], -font=> $StdTextFont,
  -vscroll=> 1, -multiline=> 1, -readonly => 1,
  -foreground =>[ 0, 0, 0],
  -background=> [192,192,192],#[96,96,96],
);


sub BTConfigTextOut{
  $w_BTConfig->btconfig_RecieveText->Append( shift );
}


sub ShowBTConfigTool{
  if( $DataDisplay_IsRunning ){ TextOut("\r\nStop DataDisplay before calling BluetoothConfigTool!\r\n"); }
  my ($x, $y) = ($w_Main->GetWindowRect())[0..1];
  $w_BTConfig->Move($x+150,$y+100);
  $w_BTConfig->btconfig_RecieveText->Text('');
  $w_BTConfig->Show();
}


sub BTConfigOpenPort{
  $Port= $w_BTConfig->btconfig_Port->Text(); #$Port has COM + friendly name
  if( ExtractCom($Port) eq '' ){
    BTConfigTextOut( "\r\nPort not specified!"."\r\n" ); return 0; #this error should never happen
  }
  $p_Serial = Win32::SerialPort->new( ExtractCom($Port) );
  if( not $p_Serial ){
    BTConfigTextOut( "\r\nOpening port ".ExtractCom($Port)." FAILED!"."\r\n" ); return 0;
  }else{
    ConfigPort();
    return 1;
  }
  return 0;
}


#==============================================================================
# Event Handler f�r BT Config Tool

my $BTAutoConfigureIsRunning= 0;

sub StrToReadableStr
{ my $s= shift;
  my $ss= '';
  for(my $i=0; $i<length($s); $i+=1 ){
    my $c= ord( substr($s,$i,1) );
    if(( $c>=ord(' ') )and( $c<=ord('~') )){
      $ss.= chr($c);
    }elsif( $c==10 ){
      $ss.= '\n';
    }else{
      $ss.='*'; #$ss.='<'.sprintf("%d",$c).'>';
    }
  }
  return $ss;
}

my $ATCmdTimeDelay= 5; #100ms
my $ATCmdTimeOut= 20; #100ms
my @ATBaudRateList= ('','1200','2400','4800','9600','19200','38400','57600','115200');
my @STORMBaudRateList= ('','a','b','c','d','e','f','g','h');


sub SendATCommand{
  my $cmd= shift; my $outputflag= shift;
  _delay_ms( 100*$ATCmdTimeDelay );
  $p_Serial->owwrite_overlapped_undef( $cmd );
  my $response= '';
  my $tmo= $p_Serial->get_tick_count() + 100*$ATCmdTimeOut; #timeout in 100 ms
  while( $p_Serial->get_tick_count() < $tmo  ){
    my ($i, $s) = $p_Serial->owread_overlapped(1);
    my $ss= StrToReadableStr($s);
    if(( defined $outputflag )&&( $outputflag>0 )){ BTConfigTextOut( $ss ); }
    $response.= $ss;
    $s= $w_BTConfig->btconfig_RecieveText->GetLine(0); #this helps to avoid the next cmd to be executed too early
    Win32::GUI::DoEvents();
  };
  my $s= $response;
  return ($response,$s); #this is dirty, a call $s=SendATCommand results in $s
}

sub t_BTConfigTool_Click{ ShowBTConfigTool(''); 1; }

sub btconfig_Window_Terminate{ ClosePort(); $w_BTConfig->Hide(); 0; }

sub btconfig_Send_Click{
  BTConfigTextOut( "\r\n".'Send' );
  if( not BTConfigOpenPort() ){ ClosePort(); return 0; }
  #_delay_ms( 1000 );
  my $cmd= $w_BTConfig->btconfig_Cmd->Text();
  BTConfigTextOut( "\r\n".$cmd."\r\n" );
  my $s= SendATCommand( $cmd, 1 );
  BTConfigTextOut( "\r\n".$cmd.'->'.$s );
  BTConfigTextOut( "\r\n".'Done'."\r\n" );
  ClosePort();
  0;
}

sub btconfig_AutoConfigure_Click{
  my $cmd= ''; my $s= ''; my $response= ''; my $detectedbaud= -1;

  if( $BTAutoConfigureIsRunning==0 ){
    $BTAutoConfigureIsRunning= 1;
  }elsif( $BTAutoConfigureIsRunning==1 ){
    $BTAutoConfigureIsRunning= 2; return 0;
  }else{ return 0; }
  $w_BTConfig->btconfig_AutoConfigure->Text('Stop Auto Configure');

  BTConfigTextOut( "\r\n".'Run auto configure... '."\r\n".'(please wait, this takes few minutes)' );
  if( not BTConfigOpenPort() ){ ClosePort(); return 0; }

  #check connection
  BTConfigTextOut( "\r\n".'check connection...' );
  $s= SendATCommand( 't', 0 );
  if( $s eq 'o' ){
    BTConfigTextOut( ' OK' );
  }else{
    BTConfigTextOut( "\r\n".'connection FAILED!' );
    BTConfigTextOut( "\r\n".'Please check the COM port and/or press the Reset button on the board.' );
    goto EXIT;
  }

  #enter Qmode
  BTConfigTextOut( "\r\n".'enter BT Qmode...' );
  $s= SendATCommand( 'xQB', 0 );
  if( $s eq 'o' ){
    BTConfigTextOut( ' OK' );
  }else{
    BTConfigTextOut( "\r\n".'connection FAILED!' );
    BTConfigTextOut( "\r\n".'Please press the Reset button on the board.' );
    goto EXIT;
  }

  _delay_ms( 500 );
  #scan all baudrates
  for(my $baud=1; $baud<=8; $baud++ ){
    BTConfigTextOut( "\r\n".'scan at '.$ATBaudRateList[$baud].' bps... ' );
    if( $BTAutoConfigureIsRunning>1 ){ BTConfigTextOut( "\r\n".'auto configure ABORTED!' ); goto EXIT; }
    $cmd= $STORMBaudRateList[$baud].'AT';
    BTConfigTextOut( "\r\n".'  '.$cmd );
    $s= SendATCommand( $cmd, 0 );
    BTConfigTextOut( '->'.$s );
    if( $s ne 'ATOK' ){ BTConfigTextOut( "\r\n".'  no BT module at this baud rate' ); }else{
      BTConfigTextOut( "\r\n".'  BT module detected at '.$ATBaudRateList[$baud].' bps' );
      $detectedbaud= $baud; last;
    }
#    $s= $w_BTConfig->btconfig_RecieveText->GetLine(0); #this helps to avoid the next cmd to be executed too early
#    Win32::GUI::DoEvents();
  }

  my $error= 0;
  #BT module detected, check
  BTConfigTextOut( "\r\n".'check BT module... ' );
  $cmd= 'AT';
  BTConfigTextOut( "\r\n".'  '.$cmd );
  $s= SendATCommand( $cmd, 0 );
  BTConfigTextOut( '->'.$s );
  if( $s ne 'ATOK' ){ $error+= 0x01; }
  $cmd= 'AT+VERSION';
  BTConfigTextOut( "\r\n".'  '.$cmd.'->' );
  $s= SendATCommand( $cmd, 1 );
  if( substr($s,0,18) ne 'AT+VERSIONOKlinvor' ){ $error+= 0x02; }
  if( $error ){ BTConfigTextOut( "\r\n".'Check FAILED, something went wrong!' ); goto EXIT; }

  #BT module detected, configure
  BTConfigTextOut( "\r\n".'configure BT module... ' );
  $cmd= 'AT+BAUD8';
  BTConfigTextOut( "\r\n".'  '.$cmd );
  $s= SendATCommand( $cmd, 0 );
  BTConfigTextOut( '->'.$s );
  if( $s ne 'AT+BAUD8OK115200' ){ $error+= 0x04; }
  if( $error ){ BTConfigTextOut( "\r\n".'Configure FAILED!' ); goto EXIT; }

  my $btname= $w_BTConfig->btconfig_Name->Text();
  if( $btname eq '' ){ $btname= 'HC-06'; }
  $btname= substr( $btname, 0, 16 );
  $cmd= 'hAT+NAME'.$btname;
  BTConfigTextOut( "\r\n".'  '.$cmd );
  $s= SendATCommand( $cmd, 0 );
  BTConfigTextOut( '->'.$s );
  if( $s ne 'AT+NAME'.$btname.'OKsetname' ){ $error+= 0x20; }
  if( $error ){ BTConfigTextOut( "\r\n".'Configure FAILED!' ); goto EXIT; }

  #BT module detected, doublecheck
  BTConfigTextOut( "\r\n".'double check configuration of BT module... ' );
  $s= SendATCommand( 'h', 0 );
  $cmd= 'AT';
  BTConfigTextOut( "\r\n".'  '.$cmd );
  $s= SendATCommand( $cmd, 0 );
  BTConfigTextOut( '->'.$s );
  if( $s ne 'ATOK' ){ $error+= 0x08; }
  $cmd= 'AT+VERSION';
  BTConfigTextOut( "\r\n".'  '.$cmd.'->' );
  $s= SendATCommand( $cmd, 1 );
  if( substr($s,0,18) ne 'AT+VERSIONOKlinvor' ){ $error+= 0x10; }
  if( $error ){ BTConfigTextOut( "\r\n".'Doublecheck FAILED, something went wrong!' ); goto EXIT; }

  BTConfigTextOut( "\r\n".'Configuration of BT module was succesfull!' );
  BTConfigTextOut( "\r\n".'DONE' );
  BTConfigTextOut( "\r\n"."\r\n".'PLEASE POWER-DOWN THE BOARD. WAIT FEW SECONDS BEFORE APPLYING POWER AGAIN.' );

EXIT:
  BTConfigTextOut( "\r\n" );
  ClosePort();
  $BTAutoConfigureIsRunning= 0;
  $w_BTConfig->btconfig_AutoConfigure->Text('Auto Configure');
  0;
}


# Ende # BLUETOOTH Configuration Tool Window
###############################################################################














#-----------------------------------------------------------------------------#
###############################################################################
###############################################################################
# MAVLINK Test Window
###############################################################################
###############################################################################
#-----------------------------------------------------------------------------#
my $MavCmdTimeOut= 10;


sub SendMavlinkCmd{
  my $dooutput= 1;
  my $msg= shift; #command + payload
  my $doread= shift; if( not defined $doread ){ $doread=9; $dooutput= 0; }
  my $msglen= UCharToHexstr( length($msg)/2 - 1 );
#TextOut( "!$msglen!" );
  my $cmd= 'FE'. $msglen .'00'.'52'.'43'. $msg . '33'.'34';
  if( not $DataDisplay_IsRunning ){
    if( not OpenPort() ){ TextOut("\r\n"."WON'T BE SEND WHILE DATADISPLAY IS RUNNING!"."\r\n"); return; }
  }
  $p_Serial->owwrite_overlapped_undef( HexstrToStr($cmd) );

  my $count= 0; my $result= '';
  my $tmo= $p_Serial->get_tick_count() + 20*$ExecuteCmdTimeOut; #timeout in 100 ms
  do{
    if( $p_Serial->get_tick_count() > $tmo  ){ $result='t'; goto EXIT; }
    my ($i, $s) = $p_Serial->owread_overlapped(1);
    $result.= $s;
#TextOut( StrToHexstr($s)."!" );
     if($dooutput){TextOut( StrToHexstr($s) );}
    $count+= $i;
  }while( $count<$doread ); # xFE x01 x00 x47='G' x43='C' x96=150 x??=ack crc-low crc-high

  my $crc=0;
  #check CRC (uses MAVLINK's x25 checksum)
  $crc= unpack( "v", substr($result,$count-2,2) );
  if($dooutput){TextOut( " CRC:".UIntToHexstr($crc) );}
  #my $crc2= do_crc( $result, $count );
  my $crc2= do_crc( substr($result,1), $count );
  if($dooutput){TextOut( " CRC2:0x".UIntToHexstr($crc2)."!" );}
  #if( $crc ne $crc2 ){ return 'c'; }
  if( $crc2 != 0 ){ $result='c'; goto EXIT; }
EXIT:
#TextOut( "X".$result."X" );
  if( not $DataDisplay_IsRunning ){
    ClosePort();
  }
}


my $MavlinkXPos= 100;
my $MavlinkYPos= 100;

$xsize= 510;
$ysize= 400;

my $w_Mavlink= Win32::GUI::DialogBox->new( -name=> 'm_mav_Window',  -parent => $w_Main, -font=> $StdWinFont,
    -text=> "Mavlink",
    -pos=> [$MavlinkXPos,$MavlinkYPos],
    -size=> [$xsize,$ysize],
   -helpbox => 0,
);
$w_Mavlink->SetIcon($Icon);


$xpos= 20;
$ypos= 20;
$w_Mavlink->AddButton( -name=> 'm_mav_PitchUp', -font=> $StdWinFont,
  -text=> 'PitchUp', -pos=> [$xpos,$ypos-3], -width=> 100,
  -onClick=> sub{ TextOut( "\r\n"."PitchUp"."\r\n" ); SendMavlinkCmd( '0A' . 'E803' ); 1; },
);
$w_Mavlink->AddButton( -name=> 'm_mav_PitchMid', -font=> $StdWinFont,
  -text=> 'PitchMid', -pos=> [$xpos,$ypos-3+25], -width=> 100,
  -onClick=> sub{ TextOut( "\r\n"."PitchMid"."\r\n" ); SendMavlinkCmd( '0A' . 'DC05' ); 1; },
);
$w_Mavlink->AddButton( -name=> 'm_mav_PitchDown', -font=> $StdWinFont,
  -text=> 'PitchDown', -pos=> [$xpos,$ypos-3+50], -width=> 100,
  -onClick=> sub{ TextOut( "\r\n"."PitchDown"."\r\n" ); SendMavlinkCmd( '0A' . 'D007' ); 1; },
);
$w_Mavlink->AddButton( -name=> 'm_mav_PitchReCenter', -font=> $StdWinFont,
  -text=> 'PitchReCenter', -pos=> [$xpos,$ypos-3+75], -width=> 100,
  -onClick=> sub{ TextOut( "\r\n"."PitchReCenter"."\r\n" ); SendMavlinkCmd( '0A' . '0000' ); 1; },
);


$xpos+= 120;
$w_Mavlink->AddButton( -name=> 'm_mav_RollUp', -font=> $StdWinFont,
  -text=> 'RollUp', -pos=> [$xpos,$ypos-3], -width=> 100,
  -onClick=> sub{ TextOut( "\r\n"."RollUp"."\r\n" ); SendMavlinkCmd( '0B' . 'E803' ); 1; },
);
$w_Mavlink->AddButton( -name=> 'm_mav_RollMid', -font=> $StdWinFont,
  -text=> 'RollMid', -pos=> [$xpos,$ypos-3+25], -width=> 100,
  -onClick=> sub{ TextOut( "\r\n"."RollMid"."\r\n" ); SendMavlinkCmd( '0B' . 'DC05' ); 1; },
);
$w_Mavlink->AddButton( -name=> 'm_mav_RollDown', -font=> $StdWinFont,
  -text=> 'RollDown', -pos=> [$xpos,$ypos-3+50], -width=> 100,
  -onClick=> sub{ TextOut( "\r\n"."RollDown"."\r\n" ); SendMavlinkCmd( '0B' . 'D007' ); 1; },
);
$w_Mavlink->AddButton( -name=> 'm_mav_RollReCenter', -font=> $StdWinFont,
  -text=> 'RollReCenter', -pos=> [$xpos,$ypos-3+75], -width=> 100,
  -onClick=> sub{ TextOut( "\r\n"."RollReCenter"."\r\n" ); SendMavlinkCmd( '0B' . '0000' ); 1; },
);

$xpos+= 120;
$w_Mavlink->AddButton( -name=> 'm_mav_YawUp', -font=> $StdWinFont,
  -text=> 'YawUp', -pos=> [$xpos,$ypos-3], -width=> 100,
  -onClick=> sub{ TextOut( "\r\n"."YawUp"."\r\n" ); SendMavlinkCmd( '0C' . 'E803' ); 1; },
);
$w_Mavlink->AddButton( -name=> 'm_mav_YawMid', -font=> $StdWinFont,
  -text=> 'YawMid', -pos=> [$xpos,$ypos-3+25], -width=> 100,
  -onClick=> sub{ TextOut( "\r\n"."YawMid"."\r\n" ); SendMavlinkCmd( '0C' . 'DC05' ); 1; },
);
$w_Mavlink->AddButton( -name=> 'm_mav_YawDown', -font=> $StdWinFont,
  -text=> 'YawDown', -pos=> [$xpos,$ypos-3+50], -width=> 100,
  -onClick=> sub{ TextOut( "\r\n"."YawDown"."\r\n" ); SendMavlinkCmd( '0C' . 'D007' ); 1; },
);
$w_Mavlink->AddButton( -name=> 'm_mav_YawReCenter', -font=> $StdWinFont,
  -text=> 'YawReCenter', -pos=> [$xpos,$ypos-3+75], -width=> 100,
  -onClick=> sub{ TextOut( "\r\n"."YawReCenter"."\r\n" ); SendMavlinkCmd( '0C' . '0000' ); 1; },
);


$xpos= 20;
$ypos= 20 + 50+ 25+25+20;

$w_Mavlink->AddButton( -name=> 'm_mav_AuxKeyMode0', -font=> $StdWinFont,
  -text=> 'ActivePanMode Default', -pos=> [$xpos,$ypos-3], -width=> 140,
  -onClick=> sub{ TextOut( "\r\n"."Aux Key off-off"."\r\n" ); SendMavlinkCmd( '64' . '00' ); 1; },
);
$ypos+= 25;
$w_Mavlink->AddButton( -name=> 'm_mav_AuxKeyMode1', -font=> $StdWinFont,
  -text=> 'ActivePanModeSetting #1', -pos=> [$xpos,$ypos-3], -width=> 140,
  -onClick=> sub{ TextOut( "\r\n"."Aux Key off-on"."\r\n" ); SendMavlinkCmd( '64' . '01' ); 1; },
);
$ypos+= 25;
$w_Mavlink->AddButton( -name=> 'm_mav_AuxKeyMode2', -font=> $StdWinFont,
  -text=> 'ActivePanModeSetting #2', -pos=> [$xpos,$ypos-3], -width=> 140,
  -onClick=> sub{ TextOut( "\r\n"."Aux Key on-off"."\r\n" ); SendMavlinkCmd( '64' . '02' ); 1; },
);
$ypos+= 25;
$w_Mavlink->AddButton( -name=> 'm_mav_AuxKeyMode3', -font=> $StdWinFont,
  -text=> 'ActivePanModeSetting #3', -pos=> [$xpos,$ypos-3], -width=> 140,
  -onClick=> sub{ TextOut( "\r\n"."Aux Key on-on"."\r\n" ); SendMavlinkCmd( '64' . '03' ); 1; },
);


$xpos+= 160;
$ypos= 20 + 50+ 25+25+20;
$w_Mavlink->AddButton( -name=> 'm_mav_SetStandBy', -font=> $StdWinFont,
  -text=> 'Set StandBy', -pos=> [$xpos,$ypos-3], -width=> 140,
);
$ypos+= 25;
$w_Mavlink->AddButton( -name=> 'm_mav_ResetStandBy', -font=> $StdWinFont,
  -text=> 'Reset StandBy', -pos=> [$xpos,$ypos-3], -width=> 140,
);

sub m_mav_SetStandBy_Click{
  TextOut( "\r\n"."Set StandBy"."\r\n" );
  SendMavlinkCmd( '0E' . '01' );
  1;
}
sub m_mav_ResetStandBy_Click{
  TextOut( "\r\n"."Reset StandBy"."\r\n" );
  SendMavlinkCmd( '0E' . '00' );
  1;
}


$xpos+= 160;
$ypos= 20 + 50+ 25+25+20;
$w_Mavlink->AddButton( -name=> 'm_mav_CameraShutter', -font=> $StdWinFont,
  -text=> 'Shutter', -pos=> [$xpos,$ypos-3], -width=> 140,
);
$w_Mavlink->AddButton( -name=> 'm_mav_CameraShutterDelayed', -font=> $StdWinFont,
  -text=> 'Shutter Delayed', -pos=> [$xpos,$ypos-3+25], -width=> 140,
);
$w_Mavlink->AddButton( -name=> 'm_mav_CameraVideoOn', -font=> $StdWinFont,
  -text=> 'Video On', -pos=> [$xpos,$ypos-3+50], -width=> 140,
);
$w_Mavlink->AddButton( -name=> 'm_mav_CameraVideoOff', -font=> $StdWinFont,
  -text=> 'Video Off', -pos=> [$xpos,$ypos-3+75], -width=> 140,
);
$w_Mavlink->AddButton( -name=> 'm_mav_CameraReset', -font=> $StdWinFont,
  -text=> 'Reset', -pos=> [$xpos,$ypos-3+100], -width=> 140,
);

sub m_mav_CameraShutter_Click{
  TextOut( "\r\n"."Shutter"."\r\n" );
  SendMavlinkCmd( '0F'. 'aa'.'01'.'aaaaaaaa' );
  1;
}
sub m_mav_CameraShutterDelayed_Click{
  TextOut( "\r\n"."Shutter Delayed"."\r\n" );
  SendMavlinkCmd( '0F'. 'aa'.'02'.'aaaaaaaa' );
  1;
}
sub m_mav_CameraVideoOn_Click{
  TextOut( "\r\n"."Video On"."\r\n" );
  SendMavlinkCmd( '0F'. 'aa'.'03'.'aaaaaaaa' );
  1;
}
sub m_mav_CameraVideoOff_Click{
  TextOut( "\r\n"."Video Off"."\r\n" );
  SendMavlinkCmd( '0F'. 'aa'.'04'.'aaaaaaaa' );
  1;
}
sub m_mav_CameraReset_Click{
  TextOut( "\r\n"."Camera Reset"."\r\n" );
  SendMavlinkCmd( '0F'. 'aa'.'00'.'aaaaaaaa' );
  1;
}


$xpos= 20;
$ypos= 20 + 50+ 25+25+20 + 100 + 20;
$w_Mavlink->AddButton( -name=> 'm_mav_GetVersion', -font=> $StdWinFont,
  -text=> 'Get Version', -pos=> [$xpos,$ypos-3], -width=> 140,
  -onClick=> sub{ TextOut( "\r\n"."Get Version"."\r\n" ); SendMavlinkCmd( '01', 8+2*3 ); 1; },
);

$ypos+= 25;
$w_Mavlink->AddButton( -name=> 'm_mav_GetParameter', -font=> $StdWinFont,
  -text=> 'Get Parameter', -pos=> [$xpos,$ypos-3], -width=> 140,
);
$w_Mavlink->AddLabel( -name=> 'm_mav_GetParameter_label', -font=> $StdWinFont,
  -text=> "Nr", -pos=> [$xpos+150,$ypos],
);
$w_Mavlink->AddTextfield( -name=> 'm_mav_GetParameter_Nr', -font=> $StdWinFont,
  -pos=> [$xpos+150+$w_Mavlink->m_mav_GetParameter_label->Width()+3,$ypos-3], -size=> [40,23],
);
$w_Mavlink->m_mav_GetParameter_Nr->Text(0);

sub m_mav_GetParameter_Click{
  TextOut( "\r\n"."Get Parameter"."\r\n" );
  my $s= $w_Mavlink->m_mav_GetParameter_Nr->Text();
  #TextOut( UCharToHexstr($s) );
  SendMavlinkCmd( '03'. UCharToHexstr($s).'00', 8+2*2 );
  1;
}

$ypos+= 25;
$w_Mavlink->AddButton( -name=> 'm_mav_SetParameter', -font=> $StdWinFont,
  -text=> 'Set Parameter', -pos=> [$xpos,$ypos-3], -width=> 140,
);
$w_Mavlink->AddLabel( -name=> 'm_mav_SetParameterNr_label', -font=> $StdWinFont,
  -text=> "Nr", -pos=> [$xpos+150,$ypos],
);
$w_Mavlink->AddTextfield( -name=> 'm_mav_SetParameter_Nr', -font=> $StdWinFont,
  -pos=> [$xpos+150+$w_Mavlink->m_mav_SetParameterNr_label->Width()+3,$ypos-3], -size=> [40,23],
);
$w_Mavlink->m_mav_SetParameter_Nr->Text(0);
$w_Mavlink->AddLabel( -name=> 'm_mav_SetParameterValue_label', -font=> $StdWinFont,
  -text=> "Value", -pos=> [$xpos+210,$ypos],
);
$w_Mavlink->AddTextfield( -name=> 'm_mav_SetParameter_Value', -font=> $StdWinFont,
  -pos=> [$xpos+210+$w_Mavlink->m_mav_SetParameterValue_label->Width()+3,$ypos-3], -size=> [40,23],
);
$w_Mavlink->m_mav_SetParameter_Value->Text(0);

sub m_mav_SetParameter_Click{
  TextOut( "\r\n"."Set Parameter"."\r\n" );
  my $s= $w_Mavlink->m_mav_SetParameter_Nr->Text();
  $s= UCharToHexstr($s).'00';
  TextOut( $s.'!' );
  my $v= $w_Mavlink->m_mav_SetParameter_Value->Text();
  if( $v<0 ){ $v = $v+65536; }
  $v= UIntToHexstr($v);
  $v= substr($v,2,2).substr($v,0,2);
  TextOut( $v.'!' );
  SendMavlinkCmd( '04'. $s.$v ); #SendMavlinkCmd( '02'. '0000'.'6400' );
  1;
}



$ypos+= 25;
$w_Mavlink->AddButton( -name=> 'm_mav_GetData', -font=> $StdWinFont,
  -text=> 'Get Data', -pos=> [$xpos,$ypos-3], -width=> 140,
  -onClick=> sub{ TextOut( "\r\n"."Get Data"."\r\n" ); SendMavlinkCmd( '05'. '00', 72 ); 1; }, # 8 +2 + 2*31 = 72
);








sub m_mav_Window_Terminate{ $w_Mavlink->Hide(); 0; }



sub t_MavlinkTool_Click{
  my ($x, $y) = ($w_Main->GetWindowRect())[0..1];
  $w_Mavlink->Move($x+100,$y+100);
  #$w_Mavlink->btconfig_RecieveText->Text('');
  $w_Mavlink->Show();
  1;
}










###############################################################################
# HELP Window
###############################################################################
my $w_Help= Win32::GUI::Window->new( -name=> 'help_Window',
    -text=> "Help for BLHeliTool",
    -pos=> [$HelpXPos,$HelpYPos],
    -size=> [$HelpWidth,$HelpHeight],
    -resizable=>1,
);

$w_Help->AddRichEdit(
    -name=> 'help_Text', -pos=> [-1,-1], -size=> [$HelpXPos,$HelpYPos],
    -font=> $StdHelpFont,
    -multiline=> 1,
    -hscroll=> 0, -vscroll=> 1,
    -autohscroll=> 0, -autovscroll=> 1,
    -keepselection => 0 ,
    -readonly=>1,
);

#==============================================================================
# Event Handler f�r Help

sub help_Window_Resize {
  my ($width, $height) = ($w_Help->GetClientRect())[2..3];
  $w_Help->help_Text->Resize($width+2, $height+2) if exists $w_Help->{help_Text};
  1;
}

sub help_Window_Terminate{ $w_Help->Hide(); 0;}

#sub m_CloseHelp_Click{ $w_Help->Hide(); 1; }

sub ShowHelp{
  my $flag= shift;
  $w_Help->help_Text->Text('');
  $w_Help->help_Text->Text( $HelpText );
  $w_Help->BringWindowToTop();
  $w_Help->Show();
}

# Ende Help
###############################################################################




###############################################################################
# Allgemeine Subroutinen
###############################################################################

sub sqr{ my $x=shift; return $x*$x; }

sub divide{ my $x= shift; my $y= shift; my $z= 0; eval '$z= $x/$y;'; return $z; }


sub StrToDez{
  my $s= shift;
  if( substr($s,0,2) eq '0x' ){ $s= HexstrToDez($s); }
  return $s;
}

sub HexstrToDez{ return hex(shift); }

sub HexstrToStr{ return pack('H*',shift); }

sub UCharToHexstr{ return uc(sprintf("%02lx",shift)); }

sub UIntToHexstr{ return uc(sprintf("%04lx",shift)); }

sub UCharToBitstr{ return uc(sprintf("%08lb",shift)); }

sub UIntToBitstr{ return uc(sprintf("%016lb",shift)); }

sub DezToHexstr{ return uc(sprintf("%0x",shift)); }

sub StrToHexstr{ return uc(unpack('H*',shift)); }

sub IntelHexChkSum{
  my $s= shift;
  my $sum=0;
  $sum+= $_ for unpack('C*', pack("H*", $s));
  my $hex_sum= DezToHexstr( $sum );
  $hex_sum = substr($hex_sum, -2); # just save the last byte of sum
  my $chksum = ( hex($hex_sum) ^ 0xFF) + 1; # 2's complement of hex_sum
  $chksum= UCharToHexstr( $chksum );
  return $chksum;    # put is back to the end of string, done
}

sub IntelHexLineType{ # :10 0100 00 214601360121470136007EFE09D21901 40  = len adr type data cc
  return substr(shift,7,2);
}

sub IntelHexLineAdr{ # :10 0100 00 214601360121470136007EFE09D21901 40  = len adr type data cc
  return HexstrToDez(substr(shift,3,4));
}

sub IntelHexLineData{ # :10 0100 00 214601360121470136007EFE09D21901 40  = len adr type data cc
  my $data= substr(shift,9,300);
  $data=~ s/.{2}$//g; #remove last CC
  return $data;
}

sub ExtractIntelHexLine{ # :10 0100 00 214601360121470136007EFE09D21901 40  = len adr type data cc
  my $line= shift;
  my $len= HexstrToDez(substr($line,1,2));
  my $adr= HexstrToDez(substr($line,3,4));
  my $type= substr($line,7,2);
  my $data= substr($line,9,300);
  $data=~ s/.{2}$//g; #remove last CC
  return ($len, $adr, $data, $type);
}

sub TrimStrToLength{ #fills str with space, and cuts str to length
  my $s= shift; my $len= shift;
  while( length($s)<$len ){ $s= $s.' '; }
  return substr($s,0,$len);
}

sub StrToHexstrFull{
  my $s= shift;
  my $ss='';
  for(my $i=0; $i<length($s); $i++ ){ $ss.= "x".sprintf("%02lx",ord(substr($s,$i,1)))." ";  }
  return $ss;
}

sub StrToHexDump{
  my $s= shift;
  my $ss=''; my $j= 0;
  for(my $i=0; $i<length($s); $i++ ){
    if( $j==0 ){ if($i==0){$ss.="0x0000: ";}else{$ss.= "0x".sprintf("%04x",$i).": ";} }
    $ss.= sprintf("%02lx",ord(substr($s,$i,1)))." ";
    $j++;
    if( $j>=16 ){ $j= 0; if( $i<length($s)-1){$ss.="\r\n";} }
  }
  return $ss;
}

sub CleanLeftRightStr{
  my $s= shift;
  $s=~ s/^[ \s]*//; #remove blanks&cntrls at begin
  $s=~ s/[ \s]*$//; #remove blanks&cntrls at end
  return $s;
}

sub CleanUpStr{
  my $s= shift;
  $s=~ s/[ \s]+//g; #remove blanks and cntrls  original $s=~ s/\s+/ /g;
  $s=~ s/^[ \s]*//;
  $s=~ s/[ \s]*$//; #clean it up
  return $s;
}

sub PathStr{
  my $s= shift;
  if( $s =~ /(.*)\\/ ){ return $1; }else{ return ''; }
}

sub NameExtStr{
  my $s= shift;
  if( $s =~ /.*\\(.*)/ ){ return $1; }else{ return ''; }
}

sub RemoveExt{
  my $s= shift;
  my $path= PathStr( $s );
  my $file= NameExtStr( $s );
  $file=~ s/(.*)\..*/$1/;
  if( $path eq '' ){ $s= $file; }else{ $s= $path.'\\'.$file;}
  return $s;
}

sub RemoveBasePath{
  my $s= shift;
  my $ss= lc($s);
  my $bb= lc($ExePath.'\\');
  my $i= index( $ss, $bb );
  if( $i==0 ){ return substr($s,length($bb),255); }else{ return $s; }
}

# integer division: compute $n div $d (so 4 div 2 is 2, 5 div 2 is also 2)
# parameters are $n then $d
sub quotient {
  my $n = shift; my $d = shift;
  my $r = $n; my $q = 0;
  while( $r >= $d ){	$r = $r - $d; $q = $q + 1; }
  return $q;
}


###############################################################################
# Dialog Handler
# und fehlende Eventhandler
###############################################################################

$w_Main-> Show();
Win32::GUI::Dialog();
if( $p_Serial ){ $p_Serial->close; }
undef $p_Serial;


if( not defined $IniFile ){
  open(F,">$IniFileName");
  print F "[SYSTEM]\n\n";
  close( F );
  $IniFile = new Config::IniFiles( -file => $IniFileName );
}
if( defined $IniFile ){

$IniFile->newval( 'PORT', 'Port', ExtractCom($w_Main->m_Port->Text()) );

#$IniFile->newval( 'SYSTEM', 'ToolsFile', $ToolsFile );
$IniFile->newval( 'SYSTEM', 'XPos', $w_Main->AbsLeft() );
$IniFile->newval( 'SYSTEM', 'YPos', $w_Main->AbsTop() );
#$IniFile->newval( 'SYSTEM','TerminalFile', $TerminalFile );

$IniFile->newval( 'SYSTEM', 'HelpXPos', $w_Help->AbsLeft() );
$IniFile->newval( 'SYSTEM', 'HelpYPos', $w_Help->AbsTop() );
my ($xx, $yy, $width, $height) = ($w_Help->GetWindowRect()); $width-= $xx; $height-=$yy;
$IniFile->newval( 'SYSTEM', 'HelpWidth', $width );
$IniFile->newval( 'SYSTEM', 'HelpHeight', $height );
$IniFile->newval( 'SYSTEM', 'DataDisplayXPos', $w_DataDisplay->AbsLeft() );
$IniFile->newval( 'SYSTEM', 'DataDisplayYPos', $w_DataDisplay->AbsTop() );
$IniFile->newval( 'SYSTEM', 'FontName', $StdWinFontName );
$IniFile->newval( 'SYSTEM', 'FontSize', $StdWinFontSize );
$IniFile->newval( 'SYSTEM', 'TextFontSize', $StdTextFontSize );

$IniFile->newval( 'TIMING', 'ReadIntervalTimeout', $ReadIntervalTimeout );
$IniFile->newval( 'TIMING', 'ReadTotalTimeoutMultiplier', $ReadTotalTimeoutMultiplier );
$IniFile->newval( 'TIMING', 'ReadTotalTimeoutConstant', $ReadTotalTimeoutConstant );

$IniFile->newval( 'TIMING', 'ExecuteCmdTimeOut', $ExecuteCmdTimeOut );
$IniFile->newval( 'TIMING', 'OpenPortDelay', $OpenPortDelay );

$IniFile->newval( 'DIALOG', 'OptionInvalidColor', '0x'.sprintf("%06x",$OptionInvalidColor) );
$IniFile->newval( 'DIALOG', 'OptionValidColor', '0x'.sprintf("%06x",$OptionValidColor) );
$IniFile->newval( 'DIALOG', 'OptionModifiedColor', '0x'.sprintf("%06x",$OptionModifiedColor) );

$IniFile->newval( 'FLASH', 'Board', $f_Tab{flash}->m_flash_Board->Text() );
$IniFile->newval( 'FLASH', 'HexFileDir', $f_Tab{flash}->m_flash_HexFileDir->Text() );
$IniFile->newval( 'FLASH', 'Version', $f_Tab{flash}->m_flash_Version->Text() );
$IniFile->newval( 'FLASH', 'Programmer', $f_Tab{flash}->m_flash_STM32Programmer->Text() );
$IniFile->newval( 'FLASH', 'STLinkPath', $STLinkPath );
$IniFile->newval( 'FLASH', 'STMFlashLoaderPath', $STMFlashLoaderPath );

$IniFile->RewriteConfig();
undef $IniFile;
}


###############################################################################
###############################################################################
