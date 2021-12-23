#ifndef UNCONTENDED_H
#define UNCONTENDED_H

//UNCONTENDED RAM

unsigned char multiply2numbers (unsigned char A, unsigned char B)
{
	return A * B;
}

void enable_interupts (void)
{
    __asm
    ei
    __endasm
}

void disable_interupts (void)
{
    __asm
    di
    __endasm
}

void ZX0_decompress (unsigned int destination, unsigned int source)
{
    //  HL: source address (compressed data)
    //  DE: destination address (decompressing)
    zx0_destination = destination;
    zx0_source = source;
    dzx0_turbo();
}

void key_test (void)
{
    if (in_key_pressed( IN_KEY_SCANCODE_0 ))
    {
        zx_border(INK_BLACK);// = 0 = black
    }
    if (in_key_pressed( IN_KEY_SCANCODE_1 ))
    {
        zx_border(1);
    }
    if (in_key_pressed( IN_KEY_SCANCODE_2 ))
    {
         border_Change_uncontended(2);// = 2 = red
    }
    if (in_key_pressed( IN_KEY_SCANCODE_3 ))
    {
        border_Change_RAM0(3);// = 3 = magenta
    }
    if (in_key_pressed( IN_KEY_SCANCODE_4 ))
    {
        border_Change_RAM0(4);// = 4 = green
    }
    if (in_key_pressed( IN_KEY_SCANCODE_5 ))
    {
        border_Change_RAM0(5);// = 5 = cyan
    }
    if (in_key_pressed( IN_KEY_SCANCODE_6 ))
    {
        border_Change_RAM0(6);// = 3 = yellow
    }
    if (in_key_pressed( IN_KEY_SCANCODE_7 ))
    {
        zx_border(INK_WHITE);// = 7 = white
    }
}

void pauseLoop (unsigned long length)//attention changed
{
    for(pauseTemp = 0; pauseTemp < length; pauseTemp++)
    {	key_test();    }
}

void showScreen1(void)
{
    //attention new
    disable_interupts();
    bank_switch (1);//attention new
    ZX0_decompress (16384, &screen1);
    //bank = 0;
    bank_switch (0);//attention new
    enable_interupts();
    pauseLoop (100000);
}

void showScreen2(void)
{
    //attention new
    disable_interupts();
    bank_switch (1);//attention new
    ZX0_decompress (16384, &screen2);
    //bank = 0;
    bank_switch (0);//attention new
    enable_interupts();
    pauseLoop (100000);
}

void showScreen3(void)
{
    //attention new
    disable_interupts();
    bank_switch (1);//attention new
    ZX0_decompress (16384, &screen3);
    bank_switch (0);//attention new
    enable_interupts();
    pauseLoop (100000);
}

void showScreen4(void)
{
    //attention new
    disable_interupts();
    bank_switch (1);//attention new
    ZX0_decompress (16384, &screen4);
    bank_switch (0);//attention new
    enable_interupts();
    pauseLoop (100000);
}

void showScreen5(void)
{
    //attention new
    disable_interupts();
    bank_switch (3);//attention new
    ZX0_decompress (16384, &screen5);
    bank_switch (0);//attention new
    enable_interupts();
    pauseLoop (100000);
}
}

void showScreen6(void)
{
    //attention new
    disable_interupts();
    bank_switch (4);//attention new
    ZX0_decompress (16384, &screen6);
    bank_switch (0);//attention new
    enable_interupts();
    pauseLoop (100000);
}

void showScreen7(void)
{
    //attention new
    disable_interupts();
    bank_switch (6);//attention new
    ZX0_decompress (16384, &screen7);
    bank_switch (0);//attention new
    enable_interupts();
    pauseLoop (100000);
}


#endif
