# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

use strict;
use warnings;

package Net::OpenStack::Neutron;
use Moose;
use 5.014002;

use Carp;
use LWP;
use JSON qw(from_json to_json);

our $VERSION = '0.02';

has auth_url     => (is => 'rw', required => 1);
has user         => (is => 'ro', required => 1);
has password     => (is => 'ro', required => 1);
has tenant   	 => (is => 'ro', required => 1);
has service_name => (is => 'ro', default => 'neutron');
has region       => (is => 'ro');
has verify_ssl   => (is => 'ro', default => 1);
has verbose      => (is => 'rw', default => 0);
 
has base_url => (
    is      => 'rw',
    lazy    => 1,
    default => sub { shift->_auth_info->{base_url} },
    writer  => '_set_base_url',
);
has token => (
    is      => 'ro',
    lazy    => 1,
    default => sub { shift->_auth_info->{token} },
);
has _auth_info => (
    is => 'ro', 
    lazy => 1, 
    builder => '_build_auth_info',
);
 
has _agent => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $agent = LWP::UserAgent->new(
            ssl_opts => { verify_hostname => $self->verify_ssl });
        return $agent;
    },
);

with 'Net::OpenStack::AuthRole';

sub BUILD {
    my ($self) = @_;
    # Make sure trailing slashes are removed from auth_url
    my $auth_url = $self->auth_url;
    $auth_url =~ s|/+$||;
    $self->auth_url($auth_url);
}

sub set_base_url {
    my ($self, $url) = @_;
    return $self->_set_base_url($url);
}

sub _build_auth_info {
    my ($self) = @_;
    my $auth_info = $self->get_auth_info();
    $self->_agent->default_header(x_auth_token => $auth_info->{token});
    return $auth_info;
}

sub _get_query {
    my %params = @_;
    my $q = $params{query} or return '';
    for ($q) { s/^/?/ unless /^\?/ }
    return $q;
};

# Neutron
sub agent_list {
    my ($self, %params) = @_;
    my $q = _get_query(%params);
    my $res = $self->_get("/v2.0/agents", $q);
    return from_json($res->content)->{agents};
}

sub port_list {
    my ($self, %params) = @_;
    my $q = _get_query(%params);
    my $res = $self->_get("/v2.0/ports", $q);
    return from_json($res->content)->{ports};   
}

sub agent_show {
    my ($self, $id) = @_;
    croak "The agent id is needed" unless $id;
    my $res = $self->_get("/v2.0/agents/$id");
    return undef unless $res->is_success;
    return from_json($res->content)->{agent};
}

sub l3_agent_list_hosting_router {
    my ($self, $id) = @_;
    croak "The agent id is needed" unless $id;
    my $res = $self->_get("/v2.0/agents/$id/l3-routers");
    return undef unless $res->is_success;
    return from_json($res->content)->{routers};
}

sub router_port_list {
    my ($self, $id) = @_;
    croak "The router id is needed" unless $id;
    my $res = $self->_get("/v2.0/ports.json?device_id=$id");
    return undef unless $res->is_success;
    return from_json($res->content)->{ports};
}

sub host_port_list {
    my ($self, $host) = @_;
    croak "The host name is needed" unless $host;
    my $res = $self->_get("/v2.0/ports.json?binding:host_id=$host");
    return undef unless $res->is_success;
    return from_json($res->content)->{ports};
}

sub _url {
    my ($self, $path, $is_detail, $query) = @_;
    my $url = $self->base_url . $path;
    $url .= '/detail' if $is_detail;
    $url .= $query if $query;
    say "_url: ".$url if $self->verbose == 1;
    return $url;
}

sub _get {
    my ($self, $url) = @_;
    return $self->_agent->get($self->_url($url));
}

sub _check_res {
    my ($res) = @_;
    die $res->status_line . "\n" . $res->content
        if ! $res->is_success and $res->code != 404;
    return 1;
}

around qw( _get ) => sub {
    my $orig = shift;
    my $self = shift;
    my $res = $self->$orig(@_);
    _check_res($res);
    return $res;
};

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::OpenStack::Neutron - Bindings for the OpenStack Neutron API

=head1 SYNOPSIS

        use Net::OpenStack::Neutron;
        my $neutron = Net::OpenStack::Neutron->new(
            auth_url     => 'https://auth.us01.cloud.webzilla.com:5000/v2.0',
            user         => 'username',
            tenant       => 'tenantname',
            password     => 'password',
        );

        $neutron->agents_list();

=head1 DESCRIPTION

This class is an interface to the OpenStack Neutron API.

=head1 METHODS
 
Methods that take a hashref data param generally expect the corresponding
data format as defined by the OpenStack API JSON request objects.
See the
L<OpenStack Docs|http://docs.openstack.org/api/openstack-network/2.0/content/>
for more information.
Methods that return a single resource will return false if the resource is not
found.
Methods that return an arrayref of resources will return an empty arrayref if
the list is empty.
Methods that create, modify, or delete resources will throw an exception on
failure.

=head2 new
 
Creates a client.
 
params:
 
=over
 
=item auth_url
 
Required. The url of the authentication endpoint. For example:
C<'https://auth.us01.cloud.webzilla.com:5000/v2.0/'>
 
=item user
 
Required.
 
=item password
 
Required.
 
=item region
 
Optional.
 
=item tenant
 
Required.
 
=item service_name
 
Optional.
Default - neutron.
 
=item verify_ssl
 
Optional. Defaults to 1.
  
=back

=head2 agent_list
 
    agent_list(%params)
 
params:
 
=over
 
=item detail
 
Optional. Defaults to 0.
 
=item query
 
Optional query string to be appended to requests.
 
=back

Returns an arrayref of all the agents.

=head2 port_list

    port_list($id)

Returns an arrayref of all the ports.

=head2 agent_show
 
    agent_show($id)
 
Returns the agent with the given id or false if it doesn't exist.

=head2 l3_agent_list_hosting_router
    
    l3_agent_list_hosting_router($id)

Returns the routers which host on l3-agent with the given id or false if it doesn't exist.

=head2 router_port_list

    router_port_list($id)

List ports that belong to a given tenant, with specified id router or false if it doesn't exist.

=head1 SEE ALSO

L<OpenStack Docs|http://docs.openstack.org/api/openstack-network/2.0/content/>

=head1 AUTHOR

Dmitry, E<lt>cyberflow@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Dmitry

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
