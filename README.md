HashIds
=======

HashIds for Embarcadero Delphi Alexandria 11 based on Ivan Akimov's hashids for Pascal. 

Hashids is a small open-source library that generates short, unique, *non-sequential* ids from numbers. Unlike traditional Hashes it is reversible if you use the same salt and alphabet. It is not encryption and does not provide any security to the encoded numbers. There are no _collisions_ because the method is based on integer to hex conversion. As long as you don't change constructor arguments midway, the generated output will stay unique to your salt.

This implementation is tested to be compatible with other [implementations](https://hashids.org/).

## Notes on usage
1. Use the same salt and alphabet to encode as decode. 
2. Do not try to encode negative numbers. It won't work. The library currently supports only positive numbers and zero. If you're trying to use numbers as flags for something, simply designate the first N number of digits as internal flags.
4. Do not encode strings. We've had several requests to add this feature — "it seems so easy to add". We will not add this feature for security purposes, doing so encourages people to encode sensitive data, like passwords. This is the wrong tool for that.
5. Do not encode sensitive data. This includes sensitive integers, like numeric passwords or PIN numbers. This is not a true encryption algorithm. There are people that dedicate their lives to cryptography and there are plenty of more appropriate algorithms: bcrypt, md5, aes, sha1, blowfish. Here's a [full list](https://en.wikipedia.org/wiki/List_of_algorithms#Cryptography).

See http://www.hashids.org/ for more information and other implementations. 
