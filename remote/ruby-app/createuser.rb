#gem install net-ldap
require 'rubygems'
require 'net/ldap'

ldap = Net::LDAP.new(:host => '8bd257fbc653.techinterview.local',
                     :auth => {
                       :method => :simple,
                       :username => 'cn=Manager,dc=techinterview,dc=local',
                       :password => '123123'
                      })

if ldap.bind
    base = 'dc=techinterview,dc=local'
    filter = Net::LDAP::Filter.eq('objectclass', '*')
    ldap.search(:base => base, :filter => filter) do |object|
    puts "dn: #{object.dn}"
    end

    puts "-------After Operation----------"

    dn = "cn=George Smith, ou=people, dc=techinterview, dc=local"
    attr = {
        :cn => "George Smith",
        :objectclass => ["top", "inetorgperson"],
        :sn => "Smith",
        :mail => "gsmith@techinterview.local"
    }


    ldap.add(:dn => dn, :attributes => attr)


    ldap.search(:base => base, :filter => filter) do |object|
        puts "dn: #{object.dn}"
    end


else
  # authentication error
end