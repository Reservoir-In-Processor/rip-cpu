int main() {
    int a = 0, b = 1, c = 0;
    while (c < 100) {
        c = a + b;
        a = b;
        b = c;
    }
}