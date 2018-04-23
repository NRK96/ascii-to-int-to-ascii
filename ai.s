# Nicholas Keen
# program: atoitoa
# 10/19/2015
# program to convert integers to ascii and ascii to integers

	.text
	.global _start
	.equ  EXIT, 1

_start:
	ldr r0, [sp]		@ argc value
	add r1, sp, #4		@ argv address
	bl main			@ call main
	mov r0, #0		@ success exit code
	mov r7, #EXIT
        svc 0			@ return to OS

# program to print the current command line parameters
# modifies r0, r1, r2

	.equ WRITE, 4
	.equ STDOUT, 1
main:
	push {r4, r5, r6, lr}		@ save registers and push return address
	mov r4, r1		@ save beginning of args array
	mov r5, r0
	add r4, r4, #4		@ skip over the program name
0:	ldr r0, [r4], #4	@ get the next cmd line string & advance
	cmp r0, #0		@ are we at the end of the cmdline params?
	popeq {r4, r5, r6, pc}		@ if so, we just return to quit
# first print the command line
	mov r6, r0		@ save address of string for later
	mov r1, r0		@ prepare for a println
	mov r0, #STDOUT
	bl println
	mov r0, r6
	bl atoi			@ otherwise convert ...
	ldr r1, =itoabuff	@ load into r1, a buffer for itoa
	bl itoa			@ convert back to ASCII
	mov r1, r0		@ prepare for a println
	mov r0, #STDOUT		@ send output to STDOUT
	bl println
	b 0b			@ ... and continue processing the next param
# done -- return
	pop {r4, r5, r6, pc}		@ return to caller

# procedure: itoa
# parameters:
#    r0: a 32 bit signed integer value
#    r1: the address of a character buffer
# returns:
#    r0: the address of the character buffer containing the null-terminated
#        string of ASCII decimal digits representing the input integer,
#        starting with a minus '-' sign if the initial integer value is
#        negative.  The return value r0 is the same as the initial
#        parameter r1.

itoa:
	push {r4, r5, r6, lr}
	mov r5, r1		@ save r1
	mov r6, r1		@ save for return value
	cmp r0, #0		@ check for negative
	bge 0f
	mov r2, #'-		@ place '-' sign in r2
	strb r2, [r5], #1	@ store the '-' in the buffer if negative, and
#advance to the next position
	rsb r0, r0, #0		@ negate the number
0:
	mov r4, #0
	push {r4}		@ push a zero on the stack
1:
	bl qr10			@ call the qr10 procedure
	add r1, r1, #'0		@ convert to ascii
	push {r1}		@ push ascii value onto the stack
	cmp r0, #0		@ check for zero
	bne 1b			@ branch back if not zero
2:
	pop {r1}		@ pop a value into r1
	strb r1, [r5], #1	@ store the popped value onto the buffer
#and advance to the next position
	cmp r1, #0		@ check for zero
	bne 2b			@ branch back if not zero
	mov r0, r6		@ place the buffer address in r0
	pop {r4, r5, r6, pc}


# procedure atoi
# parameters:
#   r0: the address of a null-terminated string of ASCII decimal digits,
#       optionally beginning with an initial minus '-' sign
# returns:
#   r0: the 32-bit signed integer representation of the input string
atoi:
	push {r4, r5, lr}
	mov r4, #0		@ flag: 0=positive, 1=negative
				@ assume positive unless proven otherwise
	ldrb r1, [r0]
	cmp r1, #'-		@ check for '-'
	moveq r4, #1		@ set flag to 1
	addeq r0, r0, #1	@ advance to next character
#	ldreq r1, [r0, #1]	@ advance past the '-'
#	str r1, [r0]		@ store value back into r0
	mov r5, r0		@ save the pointer to the digit string
	mov r0, #0		@ initialze running sum to zero
0:
	ldrb r2, [r5], #1
	cmp r2, #'0		@ this will return if r2 is null
	blt 1f
	cmp r2, #'9
	bgt 1f
# at this point, we know that r2 contains an ASCII decimal digit
	bic r2, r2, #0x30	@ convert ASCII digit to its num. equiv.
	mov r1, r0		@ now multiply the running sum ...
	mov r0, r0, LSL #3
	add r0, r0, r1, LSL #1	@ ... by 10
	add r0, r0, r2		@ and add the value of the digit
	bal 0b			@ go back for more digits
1:
# handle '-' here, if we check for it
	cmp r4, #0
	rsbne r0, r0, #0	@ negate the running sum if we saw a '-'
#	mov r7, #EXIT		@ for debugging
#	svc 0
	pop {r4, r5, pc}

# unsigned divide by 10
# parameters:
#   r0 - dividend
# returns
#   r0 - quotient
#   r1 - remainder
qr10:
	mov r3, r0		@ save dividend
	ldr r1, =0x1999999a	@ 2^32/10
	sub r0, r0, r0, lsr #30	@ adjust for large dividends
	umull r2, r0, r1, r0	@ quotient in r0
	mov r1, r0, LSL #3	@ 8q
	add r1, r1, r0, LSL #1	@ 10q
	sub r1, r3, r1		@ remainder in r1
	mov pc, lr


# print the elements of a string array
# parameters
#   r0:   output file descriptor
#   r1:   string array pointer -- terminated with a null
# returns nothing
parray:
	push {r4, r5, lr}
	mov r4, r0		@ save r0 (fd)
	mov r5, r1		@ and r1 (string array pointer)
        bal 1f
0:
        mov r0, r4              @ pass fd in r0
        bl println              @ write the string
1:
        ldr r1, [r5], #4        @ get current string address, and advance
        cmp r1, #0              @ are we done?
        bne 0b                  @ no, write the string
        pop {r4, r5, pc}


# determine string length
# parameters
#   r0:   address of null-terminated string
# returns
#   r0:   length of string (excluding the null byte)
# modifies r0, r1, r2
strlen:
	mov r1, r0		@ address of string
	mov r0, #0		@ length to return
0:
	ldrb r2, [r1], #1	@ get current char and advance
	cmp r2, #0		@ are we at the end of the string?
	addne r0, #1
	bne 0b
# return
	mov pc, lr

# write a null-terminated string followed by a newline
# parameters
#   r0:  output file descriptor
#   r1:  address of string to print
# modifies r0, r1, r2
println:
	push {r4, r5, r7, lr}
# first get the string length
	mov r4, r0		@ save the fd
	mov r5, r1		@ and the string address
	mov r0, r1		@ the string address
	bl strlen		@ returns the string length in r0
	mov r2, r0		@ put length in r2 for the WRITE syscall
	mov r0, r4		@ restore the fd
	mov r1, r5		@ and the string address
	mov r7, #WRITE
	svc 0
	mov r0, r4		@ retrieve the fd
	adr r1, CR		@ get the address of the CR string
	mov r2, #1		@ one char to write
	mov r7, #WRITE
	svc 0
	pop {r4, r5, r7, pc}	@ restore registers and return to caller

CR:	.byte '\n

	.align 2
	.data
itoabuff:.space 16
