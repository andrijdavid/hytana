import torch

@torch.jit.script
def hytana_jit_fwd(x):
    ALPHA = 0.303
    BETA = 0.632
    return x/2 *(1 + torch.tanh(ALPHA+ x.mul(BETA)) )


@torch.jit.script
def hytana_jit_bwd(x, grad_output):
    ALPHA = 0.303
    BETA = 0.632
    inp = ALPHA + x.mul(BETA)
    grad_tsp = 1.0 / torch.cosh(inp)
    grad = torch.tanh(inp) + (BETA * x * grad_tsp * grad_tsp) + 1
    return  grad_output* grad / 2


class HytanaJitAutoFn(torch.autograd.Function):
    @staticmethod
    def forward(ctx, x):
        ctx.save_for_backward(x)
        return hytana_jit_fwd(x)

    @staticmethod
    def backward(ctx, grad_output):
        x = ctx.saved_tensors[0]
        return hytana_jit_bwd(x, grad_output)


def hytana_jit(x, inplace=False):
    # inplace ignored
    return HytanaJitAutoFn.apply(x)


class HytanaJit(torch.nn.Module):
    def __init__(self, inplace: bool = False):
        super(HytanaJit, self).__init__()
        self.inplace = inplace

    def forward(self, x):
        return HytanaJitAutoFn.apply(x)