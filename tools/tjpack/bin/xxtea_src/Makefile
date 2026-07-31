
xxtea_dll : main.o xxtea.o
	g++ main.o xxtea.o -o xxtea_dll
main.o : main.cpp xxtea.h
	g++ -c main.cpp -o main.o
xxtea.o : xxtea.c xxtea.h dll.h
	gcc -c xxtea.c -o xxtea.o
clean :
	rm xxtea_dll *.o
            
