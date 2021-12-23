// using sccz80 1.99c
//lesson for loading playing WYZ tracker music in banked memory
//
// need to rework and replace zx0 with newer version - done
//see https://github.com/einar-saukas/ZX0
// need to rework bankswitching code.  look at lesson 10 for solution

#include <arch/zx.h>
#include <stdio.h>//standard input output
#include <input.h>//used for detecting key inputs
#include <intrinsic.h>//temp to place labels
//powerful troubleshooting tool
        //intrinsic_label(border_start);
        //intrinsic_label(border_end);

#include "variables.h"
#include "externs.h"
#include "uncontended.h"


void main ()
{
    SETUP_IM2();// set up for the interrupt mode 2
    // this will point the I register to IM2 Vector

    disable_interupts();

    bank_switch (0);

    //attention new
    PLAYER_INIT();//we will need to initialize the player
    INIT_BUFFERS();//we will need to initialize the buffer
	PLAYER_OFF();//turn off the player

	WYZ_LOAD_SONG (0);//load a song
	//attention new

    zx_cls(PAPER_WHITE);
    printf("\x16\x01\x02");
    printf ("Main () running in uncontended\n");

    printf ("_Variable_in_contended = %d\n", Variable_in_contended);
    printf ("_Variable_in_Bank0 = %d\n", Variable_in_Bank0);

    printf ("tom = %d\n", tom);
    printf ("dick = %d\n", dick);
    printf ("harry = %d\n", harry);
    printf ("eve = %u\n", eve);
    printf ("bob = %u\n\n", bob);

    harry = add_two_numbers (tom, dick);
    printf ("Add 2 numbers %u + %u = %u\n", tom, dick, harry);

    harry = subtract2numbers (Variable_in_Bank0, eve);
    printf ("Subtract 2 numbers %u - %u = %u\n", Variable_in_Bank0, eve, harry);

    harry = multiply2numbers (Variable_in_contended, bob);
    printf ("Multiply 2 numbers %u * %u = %u\n", Variable_in_contended, bob, harry);

    harry = add_two_numbers (Variable_in_contended, Variable_in_Bank0);
    printf ("Add 2 numbers %u + %u = %u\n", Variable_in_contended, Variable_in_Bank0, harry);

    printf("\n\nPress 0-7 for Border Test\n");

    pauseLoop(5000);//attention new

    printf("Does the music play now?");

    //attention new
    bank_switch (0);//we will need to be in bank 0


    enable_interupts ();//attention new

    while(1)
    {

        intrinsic_label(inside_loop);

        showScreen1();
        showScreen2();
        showScreen3();
        showScreen4();
        showScreen5();
        showScreen6();
        showScreen7();
    }
}


// must have blank line at end


