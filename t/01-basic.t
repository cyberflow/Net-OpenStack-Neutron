use Test::Most tests => 5;
 
use Net::OpenStack::Neutron;
 
throws_ok(
    sub { Net::OpenStack::Neutron->new },
    qr(Attribute \S+ is required),
    'instantiation with no argument throws an exception'
);

throws_ok(
    sub { Net::OpenStack::Neutron->new( auth_url => 'foo' ) },
    qr(Attribute \S+ is required),
    'instantiation with only auth_url argument throws an exception'
);

throws_ok(
    sub { Net::OpenStack::Neutron->new( auth_url => 'foo', user => 'bar' ) },
    qr(Attribute \S+ is required),
    'instantiation with only auth_url, user arguments throws an exception'
);

throws_ok(
    sub { Net::OpenStack::Neutron->new( auth_url => 'foo', user => 'bar', password => 'foobar' ) },
    qr(Attribute \S+ is required),
    'instantiation with only auth_url, user, password arguments throws an exception'
);

subtest 'Bad json response' => sub {
 
    my $neutron = Net::OpenStack::Neutron->new(
        auth_url => 'http://foo.com/v42.17',
        user     => 'foo',
        tenant   => 'bar',
        password => 'foobar',
    );
    ok( defined $neutron && $neutron->isa('Net::OpenStack::Neutron'), 'new() returned object is the right class' );
    dies_ok(
        sub {
            $neutron->agent_list();
        },
        'agent_list() dies if auth_url does not return valid json'
    );
};

done_testing;