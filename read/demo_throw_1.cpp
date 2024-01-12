
__attribute__((noinline))
int g(int *x) {
  *x *= 2;
  return 100;
}

__attribute__((noinline))
int f(int *x) {
  ++*x;
  return g(x);
}

int main() {
  int x = 3;
  return f(&x);
}
