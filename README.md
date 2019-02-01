__SVN caching, How it works ?__

On Windows, the Subversion client stores passwords in the %APPDATA%/Subversion/auth/ directory. On Windows 2000 and later, the _standard Windows cryptography services_ are used to encrypt the password on disk.
Because the encryption key is managed by Windows and is tied to the user's own login credentials, only the user can decrypt the cached password.

Above text are from [svnbook.read](http://svnbook.red-bean.com/en/1.7/svn.serverconfig.netmodel.html)

__What is "Windows cryptography services" ?__

