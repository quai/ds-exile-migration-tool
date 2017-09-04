use strict;
use warnings;
use File::Slurp;
use JSON::XS;

my $filename = $ARGV[0];
if (!-e $filename) {
	print "Usage: $0 <path/to/config.cpp>\n";
	print "Dumps a JSON file called config.json in the current folder.\n";
	exit;
}

my $data = read_file($filename);
my $out = remove_whitespace($data);
my $class_tree = parse_class($out);

write_file('config.json', encode_json($class_tree));

sub parse_class {
	my ($str, $level) = @_;

	$level = (defined $level) ? $level : 0;

	if ($level > 10) { die "To deep\n"; }

	if ($str =~ s/^class ([a-zA-Z0-9_-]+)([:\{;])/$2/) {
		my $class_name = $1;
		my $base_class = '';

		if ($str =~ s/^;//) {
			return ({ name => $class_name }, $str);
		}

		if ($str =~ s/^:(.*?)\{/{/) {
			$base_class = $1;
		}

		if ($str !~ s/^\{//) {
			die "Expected {!\n";
		}

		my $class = {
			name => $class_name,
			exstends => $base_class,
			sub_class => [],
			prop => {},
		};

CONT_CLASS:
		while (length($str)) {

			if (length($str) == 0 || $str =~ s/^};//) {
				if ($level >= 1) {
					return ($class, $str);
				}
				if (length($str) == 0) {
					return $class;
				}
			}

			# Do we see another class?
			if ($str =~ m/^class /) {
				(my $_class, $str) = parse_class($str, $level+1);
				push @{$class->{'sub_class'}}, $_class;
				redo CONT_CLASS;
			}

			# Handle #include's
			if ($str =~ s/^#include "(.*?)"//) {
				my $include_file = $1;
				$include_file =~ s/\\/\//g;

				my $include_path = $filename;
				$include_path =~ s(/[^/]+$)(/);

				if (!-f "$include_path$include_file") {
					die "did not find $include_file in $include_path.\n";
				}

				my $inc = read_file("$include_path$include_file");
				$inc = remove_whitespace($inc);
				$str = $inc . $str;

				redo CONT_CLASS;
			}

			# Handle class properies
			$str =~ s/^([a-zA-Z0-9_-]+)//;
			my $prop_name = $1;

			my $prop_type = 'scalar';
			if ($str =~ s/^\[\]//) {
				$prop_type = 'array';
			}

			if ($str !~ s/=//) {
				die "Expected =\n";
			}

			my $prop_value;

			if ($prop_type eq 'scalar') {
				if ($str =~ s/^"(.*?)";//) {
					# String
					$prop_value = $1;
				} elsif ($str =~ s/^(-?[e0-9.-]+);//) {
					# Number;
					$prop_value = $1;
				} elsif ($str =~ s/^(.*?);//) {
					# Number;
					$prop_value = $1;
				} else {
					my $extr = substr($str, 0, 20);
					die "Unknown scalar value type: '$extr'\n";
				}
			} elsif ($prop_type eq 'array') {
				if ($str =~ s/^(\{.*?\});//) {
					# Skipping parsing of arrays in this version. Will implement this if
					# and when this is needed by the project.

					$prop_value = $1;
				} else {
					die "Could not parse array: '" . substr($str,0,50) ."'\n";
				}
			}

			$class->{'prop'}{$prop_name} = $prop_value;
		}

	} else {
		die "String did not start with a class!\n";
	}
	die "should not happen";
}

sub remove_whitespace {
	my ($data) = @_;

	# Remove C-style comments starting with // to the end of the line.
	$data =~ s/\s*\/\/.*$//gm;

	# Remove C-style comments like /* foo */, also over multiple lines.
	$data =~ s(/\*(?:(?!\*/).)*\*/\n?)()sg;

	# Remove any C-style #define, since they are outside of the scope for this parser.
	$data =~ s/^\s*#define.*$//gm;

	# Remove any occurance of \t \r and \n.
	$data =~ s/[\t\r\n]+//gms;

	# Remove whitespace from the start of the file.
	$data =~ s/^\s+//;

	my $out = '';
	my $inside_string = 0;
	while ($data =~ s/^(.)//) {
		my $char = $1;

		# Quite naive and stupid detection of inside/outside of double quoted strings.
		if ($char eq '"') {
			$inside_string = ($inside_string == 1) ? 0 : 1;
		} else {
			if (!$inside_string && $char =~ m/\s/ && $out =~ m/[\{\}:;=]$/) { next; }
			if (!$inside_string && $char =~ m/\s/ && $data =~ m/^(?:\s|[\{\}:;=])/) { next; }
		}

		$out .= $char;

	}
	if ($inside_string) {
		die "Unbalanced double quotes!\n";
	}
	return $out;
}