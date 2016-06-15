#!/usr/bin/perl

use v5.12;
use lib 'local/lib/perl5';

use strict;
use warnings;

use Getopt::Long;
use Config::General;

use autodie;
use Try::Tiny;
use Method::Signatures;

use JSON;
use REST::Client;
use XML::LibXML;

#---- Process name and version
my $program_name = 'feeds';
my $vn           = "1.0";

#---- Get command line options
my $debug      = 0;               # debug default value (false)
my $configFile = "cnf/config";    # config file default value (cnf/config)
my $xmlFile;                      # XML file default value (empty)
my $help;

try {
    GetOptions(
        "conf=s"    => \$configFile,
        "xmlfile=s" => \$xmlFile,
        "debug"     => \$debug,
        "help"      => \$help
    ) or die "Error in command line arguments!";
}
catch {
    say $_;
    do_help();
	do_exit(0);
};

#---- Print help if requested
if ($help) {
	do_help();
	do_exit(0);
}

#---- Load configurations
my $conf   = Config::General->new($configFile);
my %config = $conf->getall;

#---- Start Script
main();


#---- functions and methodes
sub do_help {

    print <<EOF;

Usage $0 [--conf=<config_file>] [--xmlfile=<xml_file>] [--debug] [--help]

   Parameters are:

   --conf Pass a optional configuration file to script  
   --xmlfile Pass a XML file to be processed and do not download from server.
   --debug Turn on debug log level.
   --help This help.

EOF
}

sub do_exit {
	 my $exitCode = shift;
	 loginfo("Finish Resources Insert:$exitCode");
	 exit $exitCode;
}

method getStrDate() {
    my $strDate = `date "+%Y%m%d%H%M%S"`;
    chomp($strDate);
    return $strDate;
}

sub logger {
    my ( $level, $msg ) = @_;
    my $logtime = `date "+%d%m%H%M%S"`;
    chomp($logtime);
    say $program_name . ":" . $logtime . ":" . $level . ":" . $msg;
}

func loginfo($msg) {
    logger( "INFO", $msg );
}

func logerror($msg) {
    logger( "ERROR", $msg );
}

func logdebug($msg) {
    if ($debug) {
        logger( "DEBUG", $msg );
    }
}

method dowloadFile() {

	my $resourceDir = $config{resource}{filedir};
	mkdir $resourceDir unless (-d $resourceDir) ;

	my $xmlFileName = $resourceDir . "/" . $config{resource}{filename} . "_" . getStrDate();

    my %resourceServer;
    $resourceServer{host} = $config{resource}{host};
    my $resourceRESTClient = REST::Client->new(%resourceServer);
    
    loginfo( "Fetching file: " . $config{resource}{filename} . " from " . $config{resource}{host});
    loginfo( "Downloading file: " . $config{resource}{filename} . " to " .  $xmlFileName);
    
    try {
        
        $resourceRESTClient->GET( $config{resource}{filename} );

        die "responsecode=["
          . $resourceRESTClient->responseCode()
          . "] responsemessage=["
          . $resourceRESTClient->responseContent() . "]"
          if ( $resourceRESTClient->responseCode() != 200 );

        loginfo("Downloading file: OK");
        logdebug("Downloaded file Data: " . $resourceRESTClient->responseContent() );

    }
    catch {
        logerror("Could not download resource: $_");
        do_exit(1);
    };

	#---- Save downloaded resource to local file
    
    try {

        open my $fh, ">", $xmlFileName;
        print $fh $resourceRESTClient->responseContent();
        close $fh;

        loginfo( "File created: " . $xmlFileName );

    }
    catch {
        logerror("Could not create file: $_");
        do_exit(1);
    };

    return $xmlFileName;
}

method getResourceData($xmlFileName) {

    my $xmlContext;
    try {
        my $xmlDoc = XML::LibXML->load_xml( location => $xmlFileName );
        my $xmlRoot = $xmlDoc->getDocumentElement();
        $xmlContext = XML::LibXML::XPathContext->new($xmlRoot);
    }
    catch {
        logerror("Could not load file: $_");
        do_exit(1);
    };

    my @resources;
    for my $resourceNode ( $xmlContext->findnodes('//Carga/Imoveis/Imovel') ) {

        my %resource;
        $resource{propertyCode} = $resourceNode->findvalue('CodigoImovel');
        $resource{propertyType} = $resourceNode->findvalue('TipoImovel');

        my $obs = $resourceNode->findvalue('Observacao');
        my ( $day, $month, $year, $description ) =
          $obs =~
			m/\A\Q$config{constants}{updateprefix}\E(\d{2})\/(\d{2})\/(\d{4})\. (.*)/;

        $resource{description} = $description;
        $resource{updatedAt} = sprintf( "%s-%s-%s", $year, $month, $day );

        $resource{address}{city}          = $resourceNode->findvalue('Cidade');
        $resource{address}{neighbourhood} = $resourceNode->findvalue('Bairro');
        $resource{address}{number}        = $resourceNode->findvalue('Numero');
        $resource{address}{complement}    = $resourceNode->findvalue('Complemento');
        $resource{address}{zipCode}       = $resourceNode->findvalue('CEP');

        my @photos;
        for my $photoNode (
            $xmlContext->findnodes( 'Fotos/Foto', $resourceNode ) )
        {
            my %url;
            $url{url} = $photoNode->findvalue('URLArquivo');
            push @photos, \%url;
        }
        $resource{photos} = \@photos;

        push @resources, \%resource;
    }

    loginfo( "Resources extracted: " . scalar @resources );
    return @resources;
}

func doRESTPost( $apiRESTClient, %body ) {

    loginfo("Sending POST request with "
          . $config{constants}{xmlKeyField} . "="
          . $body{ $config{constants}{xmlKeyField} } );
    my $jsonEncoder = JSON->new;
    my $jsonData    = $jsonEncoder->utf8->pretty->encode( \%body );
    logdebug( "POST request Data: " . $jsonData );

    my %httpHeaders;
    $httpHeaders{"Content-Type"} = "application/json";
    $httpHeaders{"Accept"}       = 'application/json';

    $apiRESTClient->PUT( $config{apiserver}{url}, $jsonData, \%httpHeaders );
    
    die "responsecode=["
          . $apiRESTClient->responseCode()
          . "] responsemessage=["
          . $apiRESTClient->responseContent() . "]"
          if ( $apiRESTClient->responseCode() != 200 );

    loginfo("Received Response with code=["
          . $apiRESTClient->responseCode()
          . "]. OK " );
    logdebug( "Response Data: " . $apiRESTClient->responseContent() );

}

func main() {

    loginfo("Starting Resources Insert");

    #---- Download XML if was not given
    my $xmlFileName = $xmlFile ? $xmlFile : dowloadFile();

    #---- Process data
    my @resources = getResourceData( xmlFileName => $xmlFileName );

    #---- Send POST requests to server
    my $apiRESTClient = REST::Client->new( %{ $config{apiserver} } );
    my $posted        = 0;
    for my $idx ( 0 .. $#resources ) {
        try {
            doRESTPost( $apiRESTClient, %{ $resources[$idx] } );
            $posted++;
        }
        catch {
            logerror("Could not post resource: $_");
        };
    }
    
    loginfo( "Resources posted: " . $posted );
    do_exit(0);
    
}

