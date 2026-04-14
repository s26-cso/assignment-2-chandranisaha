#include <ctype.h>
#include <dlfcn.h>
#include <limits.h>
#include <stdio.h>

typedef int (*operation_fn)(int, int);

int main(void) {
    char line[128];

    while (fgets(line, sizeof(line), stdin) != NULL) {
        char op[6];
        char extra;
        int op_chars;
        int num1;
        int num2;

        if (sscanf(line, " %5[a-z]%n", op, &op_chars) != 1) {
            continue;
        }

        if (line[op_chars] != '\0' && !isspace((unsigned char)line[op_chars])) {
            continue;
        }

        if (sscanf(line + op_chars, " %d %d %c", &num1, &num2, &extra) != 2) {
            continue;
        }

        char library_path[sizeof("./lib") + 5 + sizeof(".so")];
        if (snprintf(library_path, sizeof(library_path), "./lib%s.so", op) >= (int)sizeof(library_path)) {
            fprintf(stderr, "operation name too long\n");
            continue;
        }

        void *handle = dlopen(library_path, RTLD_NOW);
        if (handle == NULL) {
            fprintf(stderr, "%s\n", dlerror());
            continue;
        }

        dlerror();
        operation_fn operation = (operation_fn)dlsym(handle, op);
        const char *error = dlerror();
        if (error != NULL) {
            fprintf(stderr, "%s\n", error);
            dlclose(handle);
            continue;
        }

        printf("%d\n", operation(num1, num2));

        if (dlclose(handle) != 0) {
            fprintf(stderr, "%s\n", dlerror());
            return 1;
        }
    }

    return 0;
}
