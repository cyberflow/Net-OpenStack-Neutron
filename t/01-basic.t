use Test::Most tests => 1;
 
use Net::OpenStack::Neutron;
 
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