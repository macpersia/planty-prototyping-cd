sed -e 's/^\(.*<password>\)\(.*\)\(<\/password>.*\)$/\1\3/g' credentials.xml -i
sed -e 's/^\(.*<password>\)\(.*\)\(<\/password>.*\)$/\1\3/g' hudson.tools.JDKInstaller.xml -i

