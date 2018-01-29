#include <stdio.h>
#include <stdlib.h>

int mod (int a, int b){
    return a %b; 
}   

int *extendedEuclid (int a, int b){
    int *dxy = (int *)malloc(sizeof(int) *3);

    if (b ==0){
        dxy[0] =a; dxy[1] =1; dxy[2] =0;
        
        return dxy;
    }
    else{
        int t, t2;
        dxy = extendedEuclid(b, mod(a, b));
        t =dxy[1];
        t2 =dxy[2];
        dxy[1] =dxy[2];
        dxy[2] = t - a/b *t2;

        return dxy;
    }
}

int main(void)
{
    int a =23, b =5;
    int *ptr;

    ptr =extendedEuclid (a, b);
    if(ptr[2]<0){
        ptr[2] = a + ptr[2];
    }
    printf("%d = %d * %d + %d * %d \n",ptr[0], a, ptr[1], b, ptr[2] );
    printf("Decription-key ---> %d\n", ptr[2]);

    return 0;       
}