package data

import (
	"context"
	"time"
)

// contextGenerator() is a helper function that generates a new context.Context from a
// context.Context and a timeout duration.
func contextGenerator(ctx context.Context, timeout time.Duration) (context.Context, context.CancelFunc) {
	return context.WithTimeout(ctx, timeout)
}
