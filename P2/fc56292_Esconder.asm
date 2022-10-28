;fc56292

extern fc56292_Biblioteca

section .rodata
   lf db 10
   error db 'Erro ao abrir os ficheiros, talvez tenha sido passado um numero incorreto de parametros.'
   error1 db 'Erro ao ler os ficheiros, talvez tenham sido colocados ficheiros errados.'
   error2 db 'Erro, mensagem demasiado grande para esta imagem!'
   error3 db 'Erro ao criar novo ficheiro'
   sizebuftxt equ 90000    ;90000 numero maximo de caracteres
   sizebufbmp equ 1048576  ;1MiB tamanho maximo de imagem
   sizebufedi equ 1048576
   sizestringtohide equ 90000
section .data
   newfilename db 0
   filesize dd 0
   offsetsize dd 0
   maxletters dd 0
   filedesctxt dq 0    ;descriptor do txt
   filedescbmp dq 0    ;descriptor do BMP
   filedescbmpnew dq 0 ;descriptor do BMP criado
   lettercount dd 0
section .bss
   stringtohide resb sizestringtohide
   bufedi resb sizebufedi
   buftxt resb sizebuftxt    ;destino do txt aberto
   bufbmp resb sizebufbmp    ;destino do BMP aberto
section .text

global _start
_start:

  ; verificar se so foram passados argumentos
    pop r8           ;numero de argumentos passados na linha de comandos
    cmp r8, 4        ;1 e a execuçao, proximos sao passados na linha de comandos
    jne msgerro      ;caso tenha sido passado mais que um argumento
    
  ; colocar nome do txt em rsi
    pop rsi
    pop rsi

  ; abrir o txt
    mov rax,  2
    mov rdi, rsi
    xor rsi,  rsi
    syscall

    cmp rax, 0  ;verificar se foi aberto corretamente
    jl msgerro
    
    mov qword [filedesctxt], rax ;guardar o descriptor
    
  ; ler o txt, bytes ficam guardados em buf
    mov rax,  0
    mov rdi,  qword [filedesctxt]
    mov rsi,  buftxt
    mov rdx,  sizebuftxt
    syscall
    
    cmp rax, 0  ;verificar se foi lido corretamente
    jl msgerro1

    xor ecx, ecx ;preparar contador de bytes lidos

obtermensagem:
  ; copiar a mensagem contida no txt (max 1024 caracteres)
    mov al, [buftxt + ecx] 
    mov [stringtohide + ecx], al
    xor al, al
    inc ecx
    cmp ecx, sizebuftxt
    je continuar
    jmp obtermensagem

continuar: 
    xor rsi, rsi
    pop rsi

  ; abrir o BMP
    mov rax,  2
    mov rdi, rsi
    xor rsi, rsi
    syscall
    
    cmp rax, 0  ;verificar se foi aberto corretamente
    jl msgerro
    
    mov qword [filedescbmp], rax ;guardar o descriptor
    
  ; ler o BMP, bytes ficam guardados em bufbmp
    mov rax,  0
    mov rdi,  qword [filedescbmp]
    mov rsi,  bufbmp
    mov rdx,  sizebufbmp
    syscall
   
  ; salvaguardar tamanho do ficheiro
    mov  edx, [bufbmp + 2];guardar tamanho do ficheiro em filesize
    mov [filesize], edx
    
  ; salvaguardar tamanho do offset
    mov edx, [bufbmp + 10];guardar offset do ficheiro em offsetsize
    mov [offsetsize], edx
    
  ; salvaguardar numero de letras que cabem no BMP
    mov ebx, [filesize]
    mov eax, [offsetsize]
    sub ebx, eax     ;tamanho do bmp sem cabeçalho
    mov ax, bx
    shr ebx, 16
    mov dx, bx
    mov ebx, 10      ;1 caractere arcii ocupa 10 bits no bmp
    div bx
    mov [maxletters], ax

  ; colocar conteudo do BMP em buffer edidavel
    xor rax, rax
    xor rcx, rcx 

copiar:
  ; copiar bmp aberto para novo buffer
    mov ebx, [filesize]
    mov al, [bufbmp + ecx]
    mov [bufedi + ecx], al
    inc ecx
    inc edx
    cmp ecx, ebx
    jne copiar

  ; preparar para colocar mensagem do txt no BMP
    xor rdi, rdi
    xor rbx, rbx  ;limpar contador de letras colocadas
    xor rax, rax  ;limpar destino de cada letra do txt
    xor ecx, ecx  ;contador de byte do ficheiro
    mov ecx, [offsetsize] ;saltar cabeçalho
    dec ecx
    mov al, [stringtohide + r15d] ;colocar primeira letra em al
 
ignoraralpha:
    xor r14, r14    ;preparar contador de multiplos de 4    
    inc ecx
    jmp colocarbits
    
letraconcluida:
    xor rdi, rdi    ;contador de bits colocados
    inc ebx
    cmp ebx, [maxletters] ;verificar se numero de caracteres excede o tamanho da imagem
    ja msgerro2
    inc r15d
    mov al, [stringtohide + r15d] ;colocar em al nova letra em decimal
    cmp al, 0 ;verificar se chegou ao fim do txt
    je continuar1

colocarbits:   
    inc r14d            ;incrementar contador de multiplos
    cmp r14d, 4         ;cada 3 bytes analisados, nao guardar 1 (alpha)
    je ignoraralpha     ;saltar 1 (alpha) 

decparabinario:
    rol al, 1           ;preparar para ler novo bit (de + para - significativo)
    test al, 1          ;verificar se bit da mensagem e um ou zero
    jz zero
    jnz um
    
um:
    mov r13b, byte [bufedi + ecx]     ;verificar se bit menos significativo precisa de ser mudado
    test r13b, 1
    jz zeroparaum
    inc ecx               ;preparar para escrever no proximo byte do ficheiro
    inc edi               ;iteraçoes do ciclo
    cmp edi, 8            ;voltar quando uma letra estiver completa
    je letraconcluida     ;passar para proxima letra
    jne colocarbits       ;continuar bits da letra atual
     
zero:
    mov r13b, byte [bufedi + ecx]     ;verificar se bit menos sognificativo precisa de ser mudado
    test r13b, 1
    jnz umparazero
    xor r13b, r13b
    inc ecx               ;preparar para escrever no proximo byte do ficheiro
    inc edi               ;iteraçoes do ciclo
    cmp edi, 8            ;voltar quando uma letra estiver completa
    je letraconcluida     ;passar para proxima letra
    jne colocarbits       ;continuar bits da letra atual
    
zeroparaum:
  ; alterar bits do BMP caso seja necessario
    inc byte [bufedi + ecx] ;passar zero a um
    xor r13b, r13b
    inc ecx               ;preparar para escrever no proximo byte do ficheiro
    inc edi               ;iteraçoes do ciclo
    cmp edi, 8            ;voltar quando uma letra estiver completa
    je letraconcluida     ;passar para proxima letra
    jne colocarbits       ;continuar bits da letra atual
    
umparazero:
  ; alterar bits do BMP caso seja necessario
    dec byte [bufedi + ecx] ;passar um a zero
    xor r13b, r13b
    inc ecx               ;preparar para escrever no proximo byte do ficheiro
    inc edi               ;iteraçoes do ciclo
    cmp edi, 8            ;voltar quando uma letra estiver completa
    je letraconcluida     ;passar para proxima letra
    jne colocarbits       ;continuar bits da letra atual
    
continuar1:
    inc r9b          ;ler null no final do ficheiro
    cmp r9b, 1       ;caso seja o primeiro null, adicionar enter
    je linha
    cmp r9b, 2       ;caso seja o segundo null, adicionar ao buffer
    je colocarbits
    jmp continuar2

linha:
    mov al, 10       ;dar enter no final da string
    jmp colocarbits

continuar2:
  ; obter nome do ficheiro modificado
    pop rsi 
    mov [newfilename], rsi

  ; criar novo ficheiro
    mov rax, 85
    mov rdi, rsi
    mov rsi, 00400q | 00200q
    syscall
    
  ; verificar se foi criado com sucesso  
    cmp rax, 0
    jl msgerro3
    
  ; guardar o descriptor do novo ficheiro
    mov qword [filedescbmpnew], rax
    
  ; colocar buffer editado no novo ficheiro
    mov rax, 1
    mov rsi, bufedi
    mov rdi, qword [filedescbmpnew]
    syscall
    
fechartxt:
  ; fechar o ficheiro txt
    mov rax, 3
    mov rdi, qword [filedesctxt]
    syscall
    
fecharbmp1:
  ; fechar o BMP inicial
    mov rax, 3
    mov rdi, qword [filedescbmp]
    syscall
    
fecharbmp2:
  ; fechar o BMP novo
    mov rax, 3
    mov rdi, qword [filedescbmpnew]
    syscall
    jmp fim

msgerro:
  ; escrever mensagem de erro na abertura do ficheiro
    mov rax, 1
    mov rdi, 1
    mov rsi, error     ;colocar mensagem em rsi
    mov rdx, 88        ;numero da caracteres da mensagem de erro
    syscall
    jmp fimerro
    
msgerro1:
  ; escrever mensagem de erro na leitura
    mov rax, 1
    mov rdi, 1
    mov rsi, error1    ;colocar mensagem em rsi
    mov rdx, 73        ;numero da caracteres da mensagem de erro
    syscall
    jmp fimerro
    
msgerro2:
  ; escrever mensagem de erro mensagem demasiado grande para imagem
    mov rax, 1
    mov rdi, 1
    mov rsi, error2    ;colocar mensagem em rsi
    mov rdx, 49        ;numero da caracteres da mensagem de erro
    syscall
    jmp fimerro
    
msgerro3:
  ; escrever mensagem de erro ao criar nova imagem
    mov rax, 1
    mov rdi, 1
    mov rsi, error3    ;colocar mensagem em rsi
    mov rdx, 27        ;numero da caracteres da mensagem de erro
    syscall
    jmp fimerro
    
fimerro:
  ; encerrar programa com mensagem de erro
    mov rax, 1
    mov rdi, 1
    mov rsi, lf
    mov rdx, 1
    syscall
    
fim:
  ; encerrar programa
    mov rax, 60
    xor rdi, rdi
    syscall