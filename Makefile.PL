use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::OpenStack::Neutron',
    LICENSE 		  => 'GPL2',
    VERSION_FROM      => 'lib/Net/OpenStack/Neutron.pm', # finds $VERSION
    PREREQ_PM         => {
    	"Moose" => 0,
        "HTTP::Request" => 0,
        "JSON" => 0,
        "LWP" => 0,
        "Test::Most" => 0,
        # "Test::Class" => 0,
        # "Test::MockModule" => 0,
        # "Test::MockObject" => 0,
        # "Test::MockObject::Extends" => 0,
        # "Devel::StackTrace" => 0,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/OpenStack/Neutron.pm', # retrieve abstract from module
       AUTHOR         => 'Dmitry <dmitry.r\@cyberflow.net>') : ()),
);
