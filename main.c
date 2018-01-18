#include <stdio.h>
#include <stdlib.h>

extern void start(int w, int h, float *M, float c);
extern void step(float T[]);

struct matrix {
    float* _1;
    float* _2;
    int w;
    int h;
} __attribute__((__packed__));

void print(struct matrix M, int step) {
    for (int y = 0; y < M.h; ++y) {
        for (int x = 0; x < M.w; ++x) {
            if (step % 2)
                printf("%.2f ", M._1[M.w*y + x]);
            else
                printf("%.2f ", M._2[M.w*y + x]);
        }
        printf("\n");
    }
    printf("\n");
}

int main() {
    struct matrix M;
    float c = 0;

    scanf("%d %d %f", &M.w, &M.h, &c);

    if (!(M.w > 0 && M.h > 0))
        return 0;

    M._1 = aligned_alloc(16, sizeof(float) * M.w * M.h);
    if (!M._1) {
        fprintf(stderr, "Matrix size too large.");
        return 1;
    }

    M._2 = aligned_alloc(16, sizeof(float) * M.w * M.h);
    if (!M._2) {
        fprintf(stderr, "Matrix size too large.");
        return 1;
    }

    float f = 0;
    for (int y = 0; y < M.h; ++y)
        for (int x = 0; x < M.w; ++x) {
            scanf("%f", &f);
            M._1[M.w*y + x] = f;
        }

    int steps = 0;
    scanf("%d", &steps);

    if (steps > 0)
        start(M.w, M.h, (float *)&M, c);

    float T[M.h];
    for (int i = 0; i < steps; ++i) {
        for (int j = 0; j < M.h; ++j) {
            scanf("%f", &T[j]);
        }

        step(T);
        print(M, i);
    }

    free(M._1);
    free(M._2);

    return 0;
}
