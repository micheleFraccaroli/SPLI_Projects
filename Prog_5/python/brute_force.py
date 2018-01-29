import string

#crp_file = printf("Inserisci file criptato: ")
cr = open('Logos.txt.crp', "r")
dr = open('decript_file.txt', 'w')
# prendo dizionario 'italian' da path:'/usr/share/dict/'
dictionary = open('/usr/share/dict/italian', 'r')
offset = 1
cr_1 = cr.readline()
word = []
w1 = []
for d in cr_1:
    if d != ' ':
        word += d
        w1 = ''.join(word)
    else:
        break

dict_l = dictionary.readline()
i = 1
while 1:
    code = []
    word_file = []
    for c in dict_l:
        if c != '\n':
            ASCII_value = ord(c)
            c_cript = ASCII_value + offset
            # parola del dizionario criptata con l'offset corrente
            code += chr(c_cript)
            word_file = ''.join(code)
        else:
            if word_file == w1:
                print("Match finded\n")
            else:
                print("Match failed #" + str(i) + "\n")
                i = i + 1

            dict_l = dictionary.readline()
            del (c)
            #del (code)
            #del (word_file)