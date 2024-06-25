extern int data_1;
extern int *data_2;

extern char *str_1;

int add(int a, int b);

int *data_10[] = { &data_1 };

int f() {

    int *p1 = &data_1;
    typedef int (*func)(int, int);
    func pf = add;

    return pf(*p1, 1);
}

int g() {
    return add(10, 20);
}

int main()
{
    return add(data_1, data_2[10]) + f() + str_1[0];
}
