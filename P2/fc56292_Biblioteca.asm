;fc56292

section .text 

global fc56292_Biblioteca
fc56292_Biblioteca:

;converter binario para decimal (maximo 8 bits)
;este codigo começa do bit mais significativo para o menos significativo
;em que rdi contem a posiçao do 1 da esquerda para a direita
;e al e onde vai ser formado o numero decimal correspondente

    cmp rdi, 1       ;saber qual bit esta a 1, a contar do mais significativo
    je primeirobit
    
    cmp rdi, 2
    je segundobit
    
    cmp rdi, 3
    je terceirobit
    
    cmp rdi, 4
    je quartobit
    
    cmp rdi, 5
    je quintobit
    
    cmp rdi, 6
    je sextobit
    
    cmp rdi, 7
    je setimobit
    
    cmp rdi, 8
    je oitavobit

primeirobit:
    add al, 128   ;adicionar a potencia de 2 correspondente
    ret 
        
segundobit:
    add al, 64
    ret 
    
terceirobit:
    add al, 32
    ret 
     
quartobit:
    add al, 16
    ret 
    
quintobit:
    add al, 8
    ret 
    
sextobit:
    add al, 4
    ret 
    
setimobit:
    add al, 2
    ret 
    
oitavobit:
    add al, 1
    ret 