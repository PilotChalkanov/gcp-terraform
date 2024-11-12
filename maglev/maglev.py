N = 10  # Example value for N
M = 5  # Example value for M

# Initialize arrays
next = [0] * N
entry = [-1] * M  # Presume that `entry` should have a size of M
permutation = [[(j + i) % M for j in range(M)] for i in range(N)]  # Example permutation matrix

n = 0

while True:
    for i in range(N):
        c = permutation[i][next[i]]

        # Find the first available `c` in entry
        while entry[c] >= 0:
            next[i] += 1
            c = permutation[i][next[i]]

        entry[c] = i
        next[i] += 1
        n += 1

        # If we've filled M entries, exit the loop
        if n == M:
            break
    if n == M:
        break

print("entry:", entry)
print("next:", next)
