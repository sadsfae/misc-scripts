#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>

#define MAXP 1024		/* ponytail: task ceiling; raise if /proc has more */
#define TOPN 10

struct task {
	int pid;
	unsigned long long cpu;	/* absolute jiffies: utime + stime */
	long rss;			/* KiB */
	char name[64];
};

static struct task t[MAXP], old[MAXP];
static int n, nold;

/* sum of the per-core jiffies columns on line 1 of /proc/stat */
static unsigned long long jiffies(void)
{
	char line[256];
	FILE *f = fopen("/proc/stat", "r");
	unsigned long long sum = 0;
	char *s;

	if (!f)
		return 0;
	if (fgets(line, sizeof(line), f)) {
		s = strchr(line, ' ');
		while (s && *++s) {
			if (*s >= '0' && *s <= '9')
				sum += strtoull(s, &s, 10);
			else if (*s != ' ')
				break;
		}
	}
	fclose(f);
	return sum;
}

/* fills t[] with one snapshot; cpu is absolute until main subtracts old[] */
static void scan(long page_kb)
{
	DIR *d = opendir("/proc");
	struct dirent *de;

	n = 0;
	if (!d)
		return;
	while (n < MAXP && (de = readdir(d))) {
		char path[32], line[512], *p, *w;
		unsigned long long u = 0, s = 0;
		long r = 0;
		int pid = atoi(de->d_name), k = 0;
		FILE *f;

		if (pid <= 0)
			continue;
		snprintf(path, sizeof(path), "/proc/%d/stat", pid);
		f = fopen(path, "r");
		if (!f)
			continue;
		if (!fgets(line, sizeof(line), f)) {
			fclose(f);
			continue;
		}
		fclose(f);

		/* name sits between the first '(' and the last ')' */
		p = strchr(line, '(');
		w = strrchr(line, ')');
		if (!p || !w || w < p)
			continue;
		*w = '\0';
		snprintf(t[n].name, sizeof(t[n].name), "%s", p + 1);

		/* tokens after ')' are /proc fields 3..: utime 14, stime 15, rss 24 */
		for (w = strtok(w + 1, " "); w; w = strtok(NULL, " ")) {
			if (++k == 12)
				u = strtoull(w, NULL, 10);
			else if (k == 13)
				s = strtoull(w, NULL, 10);
			else if (k == 22)
				r = strtol(w, NULL, 10);
		}
		t[n].pid = pid;
		t[n].cpu = u + s;
		t[n].rss = r * page_kb;
		n++;
	}
	closedir(d);
}

static unsigned long long prev_cpu(int pid)
{
	int i;

	for (i = 0; i < nold; i++)
		if (old[i].pid == pid)
			return old[i].cpu;
	return 0;
}

static int cmp_cpu(const void *a, const void *b)
{
	const struct task *x = a, *y = b;

	if (y->cpu != x->cpu)
		return y->cpu > x->cpu ? 1 : -1;
	return x->pid - y->pid;
}

static int cmp_rss(const void *a, const void *b)
{
	const struct task *x = a, *y = b;

	if (y->rss != x->rss)
		return y->rss > x->rss ? 1 : -1;
	return x->pid - y->pid;
}

int main(void)
{
	unsigned long long t0, dt;
	long page_kb;
	int i, k;

	page_kb = sysconf(_SC_PAGESIZE) / 1024;
	t0 = jiffies();
	scan(page_kb);
	memcpy(old, t, sizeof(*old) * n);
	nold = n;
	usleep(200000);
	scan(page_kb);
	dt = jiffies() - t0;
	for (i = 0; i < n; i++)
		t[i].cpu -= prev_cpu(t[i].pid);

	k = n < TOPN ? n : TOPN;
	printf("%d tasks, %.0f ms window\n\n", n, 1000.0 * dt / sysconf(_SC_CLK_TCK));

	qsort(t, n, sizeof(*t), cmp_cpu);
	printf("top %d by CPU%% (share of all cores):\n", k);
	for (i = 0; i < k; i++)
		printf("  %6d  %-28s %5.1f%%  %8.1f MB\n", t[i].pid, t[i].name,
		       dt ? 100.0 * t[i].cpu / dt : 0.0, t[i].rss / 1024.0);

	qsort(t, n, sizeof(*t), cmp_rss);
	printf("\ntop %d by RSS:\n", k);
	for (i = 0; i < k; i++)
		printf("  %6d  %-28s %8.1f MB\n", t[i].pid, t[i].name,
		       t[i].rss / 1024.0);
	return 0;
}
