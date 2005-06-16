use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Business::OnlinePayment::CyberSource',
    'VERSION_FROM' => 'CyberSource.pm', # finds $VERSION
    'AUTHOR'       => 'Peter Bowen <pbowen@corp.untd.com>',     #really just
                                                                #the maintainer
    #'NORECURS'     => 1, # dont descend into subdirectories
    'PREREQ_PM'    => { 'cybs' => '0',
                        'Business::OnlinePayment' => '0',
                      },
    #'dist'         => {CI => 'ci -l'},
);
