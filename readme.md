
MSSQL Active Directory Sync
=============================================================
This code will let you download and keep in sync a set of tables 
with a copy of your Active Directory users and groups. It's a useful way
to do permission checks without having to query ADSI directly.

Installation
-------------------------------------------------------------
You'll need a linked server set up with access to ADSI. A script is included that will do this.
You'll just need to provide a domain account and password with permission to AD.

Then you'll need to set up the tables that will store your data. A script is included that will do this.

Then you need to perform the syncs. A stored procedure script is included that will do this.
You'll need to update the @ldap variable in this code with the information for your domain.
If your AD domain is named mydomain.local for example, you'd set it to LDAP://dc=mydomain,dc=local.
It gets more complicated than that but when it does, you'll probably already know what to do.

Now just schedule this function to run at regular intervals to keep your copy up-to-date.


Limitations
-------------------------------------------------------------
By default ADSI will only return about 900 results per query. If you have more than 900 users
(remember the disabled accounts count!) or groups, you'll need to do something about this.

The simplest workaround is to go into LDAP and increase the limit:

	http://support.microsoft.com/kb/315071

If you can't do that or don't want to, you'll have to modify the sync procedure and have to return
subsets of data - maybe filter by the first letter of the object name, etc.


Notes
-------------------------------------------------------------
All the temp tables (instead of table variables) and dynamic SQL are necessary 
because the ADSI queries include variables and you can't
run OPENQUERY against a variable, unless you run it as a dynamic statement in which case you
can't use a local table variable.



New BSD License
-------------------------------------------------------------
Copyright (c) 2012, Ron Michael Zettlemoyer.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

- Neither the names of this software's contributors nor the names of the
contributors' organizations may be used to endorse or promote products
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
