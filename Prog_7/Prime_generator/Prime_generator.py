import sys

def genera(max):
    for i in range(,max):
        primo = True
        for j in range(2,int(i/2)):
            if i%j==0:
                primo = False
                break
        if primo:
            a.append(i)
    return a    

f = open("prime.txt","w")
a =[]
a = genera(75)
a.sort()
f.write(str(a))
print([len(a)])
