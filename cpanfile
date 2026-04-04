# kind of duplicate of Makefile.PL
#	but convenient for Continuous Integration

on 'test' => sub {
    requires 'Test::More'          => 0;
    requires 'Test::Pod::Coverage' => 0;
    requires 'Test::Pod'           => 0;
    requires 'Pod::Coverage'       => 0;
    requires 'Scalar::Util'        => 0;
};
