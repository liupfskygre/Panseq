#!/usr/bin/perl

#Merged fuctionality with Deltablock reader 1/11/11 - JC
#NOTE: Start and ends of reference locations are no longer automatically adjusted to set lower value as start.
#Use reverseComplement Flag to determine if start and end values need to be reversed
#Added funtionality to allow for reading of protein alignements as well as DNA (Robustness)

package DeltaBlockFactory;

use FindBin::libs;
use IO::File;
use Mummer::DeltaBlockObject;
use Carp;
use strict;
use warnings;
use diagnostics;

#object creation
use Object::Tiny::RW qw{
  fileHandle
  header
  _refName
  _queryName
  _refLength
  _queryLength
};

sub new {
	my ($class) = shift;
	my $self = {};
	bless( $self, $class );
	$self->initialize(@_);
	return $self;
}

#methods
sub initialize {
	my ($self) = shift;

	if (@_) {
		my $fileHandle = shift;
		$self->fileHandle($fileHandle);

		#Open DeltaFile
		if ( $self->fileHandle() ) {

			#Store Header information
			my $line = $self->fileHandle()->getline();
			chomp($line);
			my $headerString = $line;
			$line = $self->fileHandle()->getline();
			chomp($line);
			$headerString .= "\n" . $line . "\n";
			$self->header($headerString);
		}
		else {
			confess "Cannot open file " . $fileHandle . "\n";
		}
	}
	else {
		print STDERR "no filehandle sent to initialize DeltaBlockFactory\n";
		exit(1);
	}
}

sub nextDeltaBlock {
	my ($self) = shift;
	my $absoluteEndValues = shift // 0;	
	
	my $deltaBlock;
	my @gapArray;
	while ( my $line = $self->fileHandle()->getline ) {
		$line =~ s/[\n\f\r]//g;
		my @lineArray = split( / /, $line );

		if ( $line =~ /^>/ ) {
			my $tempString = $lineArray[0];
			$tempString =~ s/^>//;
			$self->_refName($tempString);
			$self->_queryName( $lineArray[1] );
			$self->_refLength( $lineArray[2] );
			$self->_queryLength( $lineArray[3] );
		}
		elsif ( $line =~ /^0$/ ) {
			$deltaBlock->gapArray( \@gapArray );
			$deltaBlock->setAbsoluteStartEndValues if $absoluteEndValues;
			return $deltaBlock;
		}
		elsif ( $line =~ /^-?\d+$/ ) {
			push( @gapArray, $line );
		}
		else {
			$deltaBlock = DeltaBlockObject->new();

			$deltaBlock->refName( $self->_refName );
			$deltaBlock->queryName( $self->_queryName );
			$deltaBlock->refLength( $self->_refLength );
			$deltaBlock->queryLength( $self->_queryLength );

			$deltaBlock->refStart( $lineArray[0] );
			$deltaBlock->refEnd( $lineArray[1] );
			$deltaBlock->queryStart( $lineArray[2] );
			$deltaBlock->queryEnd( $lineArray[3] );

			#add error, similarity errors, and stop codons
			$deltaBlock->errors( $lineArray[4] );
			$deltaBlock->similarityErrors( $lineArray[5] );
			$deltaBlock->stopCodons( $lineArray[6] );
		}
	}
	return undef;
}

1;