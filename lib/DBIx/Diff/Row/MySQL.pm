package DBIx::Diff::Row::MySQL;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       diff_rows
               );

our %SPEC;

our $sch_row = ['hash', of=>'str'];

$SPEC{diff_rows} = {
    v => 1.1,
    summary => 'Compare two rows (each in a hash of scalars) and generate '.
        'SQL to update the first to the second (MySQL variant)',
    args => {
        row1 => {
            summary => 'First row',
            schema => $sch_row,
            req => 1,
            pos => 0,
        },
        row2 => {
            summary => 'Second row',
            schema => $sch_row,
            req => 1,
            pos => 1,
        },
        table => {
            summary => 'Table name',
            schema => 'str*',
        },
        key => {
            summary => 'Key name(s)',
            schema => ['any*', of=>[
                'str*',
                ['array*', of=>'str*', min_len=>1],
            ]],
        },
        insert => {
            summary => 'When first row is undef ("row not exists") and second '.
                'row is defined, whether to generate INSERT statement '.
                'to create the second row',
            schema => 'bool*',
            default => 0,
        },
        delete => {
            summary => 'When first row is defined and second row is undef '.
                '("row not exists"), whether to generate DELETE statement '.
                'to delete the row',
            schema => 'bool*',
            default => 0,
        },
        dbh => {
            summary => 'Database handle, to provide proper quoting functionality',
            schema => 'obj*',
        },
    },
    examples => [
        {
            args => {table=>'t1', key=>'id', row1=>{id=>123, f1=>1, f2=>2, f3=>undef}, row2=>{id=>123, f1=>undef, f2=>20, f3=>30}},
            result => [200, "OK", "UPDATE `t1` SET `f1`=NULL, `f2`='20', `f4`='30' WHERE `id`='123' LIMIT 1"],
        },

        {
            summary => "Both rows don't exist",
            args => {table=>'t1', key=>'id', row1=>undef, row2=>undef},
            result => [200, "Both rows don't exist", ''],
        },

        {
            summary => "First row doesn't exist, don't generate INSERT",
            args => {table=>'t1', key=>'id', row1=>undef, row2=>{id=>123, f1=>1}},
            result => [412, "Won't generate SQL to insert row"],
        },
        {
            summary => "First row doesn't exist, insert row",
            args => {table=>'t1', key=>'id', insert=>1, row1=>undef, row2=>{id=>123, f1=>1}},
            result => [200, "OK", "INSERT INTO `t1` (`f1`,`id`) VALUES ('1','123')"],
        },

        {
            summary => "Second row doesn't exist, don't generate DELETE",
            args => {table=>'t1', key=>'id', row2=>undef, row1=>{id=>123, f1=>1}},
            result => [412, "Won't generate SQL to delete row"],
        },
        {
            summary => "Second row doesn't exist, delete row",
            args => {table=>'t1', key=>'id', delete=>1, row2=>undef, row1=>{id=>123, f1=>1}},
            result => [200, "OK", "DELETE FROM `t1` WHERE `id`='123' LIMIT 1"],
        },
    ],
};
sub diff_rows {
    my %args = @_;

    my $table = $args{table}; defined($table) or return [400, "Please specify table"];
    my $keys  = $args{key};   defined($keys)  or return [400, "Please specify key"]; $keys = [$keys] unless ref $keys eq 'ARRAY'; $keys = [sort @$keys];
    my $row1 = $args{row1};
    my $row2 = $args{row2};

    my $code_quote;
    if ($args{dbh}) {
        $code_quote = sub { $args{dbh}->quote(shift) };
    } else {
        $code_quote = sub {
            my $v = shift;
            defined($v) or return 'NULL';
            $v =~ s/([\\'])/\\$1/g;
            "'$v'";
        };
    }

    if (!defined($row1) && !defined($row2)) {
        return [200, "Both rows don't exist", ''];
    } elsif (defined($row1) && !defined($row2)) {
        if ($args{delete}) {
            for my $k (@$keys) {
                defined($row1->{$k}) or return [412, "Row doesn't define key field $k"];
            }
            return [
                200, "OK",
                join(
                    "",
                    "DELETE FROM `$table` WHERE ",
                    join(" AND ", map {"`$_`=".$code_quote->($row1->{$_})} @$keys),
                    " LIMIT 1",
                ),
            ];

        } else {
            return [412, "Won't generate SQL to delete row"];
        }
    } elsif (!defined($row1) && defined($row2)) {
        if ($args{insert}) {
            # ...
        } else {
            return [412, "Won't generate SQL to insert row"];
        }
    } else {

    }
}

1;
# ABSTRACT:

=head1 SYNOPSIS


=head1 DESCRIPTION


=head2


=head1 SEE ALSO

L<DBIx::Diff::Table::MySQL>

=cut
