int add(int a, int b) {
    static int static_i = 15;
    static_i++;

    return a + b;
}

int fa() {
    typedef int (*func)(int, int);
    func pf = add;
    pf(10, 20);
}

static int static_g = 16;
static int static_arr[] = {17, 18, 19};
static int static_f(int a) { return add(a, a); }

int data_1 = 11;
int data_2[] = { 12, 13, 14};
int *data_3[] = {&data_1, data_2, &static_g, static_arr};

int bss_1;
int bss_2[10];

char *str_1 = "wwc :-)";
