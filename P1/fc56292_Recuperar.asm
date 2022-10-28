;fc56292

extern fc56292_Biblioteca

section .rodata
   error db 'Erro ao abrir a imagem, talvez tenha sido passado um numero incorreto de parametros.'
   error1 db 'Erro ao ler a imagem, talvez tenha sido colocado o ficheiro errado.'
   sizebuf equ 1024
   lf db 10
   
section .data
   filesize dd 0
   offsetsize dd 0
   pixelbytes dd 0
   filedesc dw 0
   lettercount dd 0
   
section .bss
   buf     resb sizebuf    ;destino do BMP aberto
   letters resb 0          ;ARRAY para guardar letras individuais (max 1024 caracteres)
section .text

global _start
_start:

  ; verificar se so foi passado um argumento
    pop r8           ;numero de argumentos passados na linha de comandos
    cmp r8, 2        ;1 e a execuçao, proximos sao passados na linha de comandos
    jne msgerro      ;caso tenha sido passado mais que um argumento
    
  ; colocar nome do BMP em rsi
    pop rsi
    pop rsi

  ; abrir o BMP
    mov rax,  2
    mov rdi, rsi
    xor rsi,  rsi
    syscall
    
    cmp rax, 0  ;verificar se foi aberto corretamente
    jl msgerro
    
    mov qword [filedesc], rax ;guardar o descriptor
    
  ; ler o BMP, bytes ficam guardados em buf
    mov rax,  0
    mov rdi,  qword [filedesc]
    mov rsi,  buf
    mov rdx,  sizebuf
    syscall
    
    cmp rax, 0  ;verificar se foi lido corretamente
    jl msgerro1
 
  ; salvaguardar tamanho do ficheiro
    mov  edx, [buf + 2];guardar tamanho do ficheiro em filesize
    mov [filesize], edx
    
  ; salvaguardar tamanho do offset
    mov edx, [buf + 10];guardar offset do ficheiro em offsetsize
    mov [offsetsize], edx
   
  ; salvaguardar numero de bytes uteis, excluindo cabeçalho
    mov eax, [filesize]
    mov ebx, [offsetsize]
    sub eax, ebx
    mov [pixelbytes], eax
    xor eax, eax            ;limpar eax
    
  ; recuperar o bit menos significativo de cada cor  
    xor ecx, ecx  ;preparar contador do numero de letras no array total
    mov r15d, [offsetsize] ;saltar cabeçalho
    dec r15d       ;decrementar para nao interferir com ciclos
    
lermensagem:
    xor rdi, rdi    ;preparar contador de bits lidos
    inc r15d        ;contador de bytes analisados para usar no endereçamento
    jmp lerbytes
    
ignoraralpha:
    xor r14, r14    ;preparar contador de multiplos de 4    
    inc r15d

lerbytes:   

    inc r14d           ;incrementar contador de multiplos
    cmp r14d, 4        ;cada 3 bytes analisados, nao guardar 1 (alpha)
    je ignoraralpha    ;saltar 1 (alpha)

    inc rdi        ;iteraçoes do ciclo
    cmp rdi, 9     ;quando correr 8x uma letra esta completa
    je guardar     ;guardar letra caso esteja completa
    xor bl, bl     ;colocar bl a 0
    mov bl, [buf + r15d]  ;destino temporario do byte de cor para passar ultimo bit para al
    
    inc r15d     ;preparar para ler proximo byte do ficheiro
    test bl, 1   ;verificar se bit menos significativo do byte atual e 1
    jnz um       ;caso o bit da mensagem seja 1
    jmp lerbytes
    
um:
    call fc56292_Biblioteca   ;converter mensagem de binario para decimal ao mesmo tempo que esta e lida
    jmp lerbytes

guardar:
  ; guardar a mensagem
    cmp al, 0          ;verificar se chegou ao fim da mensagem
    je imprimir
    
    dec r15d            ;decrementar contadores para nao interferir com o funcionamento dos loops
    dec r14d
    mov [letters + ecx], al    ;guardar letra no array de letras
    inc ecx                    ;proximo indice do array livre para receber uma letra
    xor al, al
    cmp r15d, [filesize]       ;comparar com tamanho do ficheiro
    je fechar                ;parar quando chegar ao fim
    jmp lermensagem
    
fechar:
  ; fechar o ficheiro
    mov rax, 3
    mov rdi, qword [filedesc]
    syscall
    
    jmp imprimir
    
msgerro:
  ; escrever mensagem de erro na abertura do ficheiro
    mov rax, 1
    mov rdi, 1
    mov rsi, error     ;colocar mensagem em rsi
    mov rdx, 84        ;numero da caracteres da mensagem de erro
    syscall
    jmp fimerro
    
msgerro1:
    ;escrever mensagem de erro na leitura
    mov rax, 1
    mov rdi, 1
    mov rsi, error1     ;colocar mensagem em rsi
    mov rdx, 67         ;numero da caracteres da mensagem de erro
    syscall
    jmp fimerro
     
imprimir:
  ; escrever mensagem na consola
    inc rcx                 ;adicionar 1 ao numero de caracteres para passar para proxima linha no final do output
    mov [lettercount], rcx
   
    mov rdi, letters  ;colocar mensagem final em rdi
    xor rcx, rcx      ;limpar rcx
    not rcx           ;inverter rcx
    xor al,al         ;iniciar al com NUL
    cld
    
    sub rcx, [lettercount]   ;numero de caracteres
    not rcx
    dec rcx
    
    mov rdx, rcx      ;imprimir cada caractere
    mov rsi, letters
    mov rax, 1
    mov rdi,rax
    syscall  
    jmp fim

fimerro:
  ; encerrar programa
    mov rax, 1
    mov rdi, 1
    mov rsi, lf
    mov rdx, 1
    syscall
    
fim:
    mov rax, 60 
    xor rdi, rdi
    syscall