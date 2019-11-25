ALL = ['PHytana', 'Hytana','HytanaFunction', 'hytana_forward','hytana_backward']

import torch # Must import torch before C extension
from ._C import hytana_forward, hytana_backward

class HytanaFunction(torch.autograd.Function):
    @staticmethod
    def forward(ctx, inp):
        ctx.save_for_backward(inp)
        return hytana_forward(inp)
    
    @staticmethod
    def backward(ctx, grad_out):
        inp, = ctx.saved_tensors
        if not ctx.needs_input_grad[0]: return (None,)
        return hytana_backward(inp, grad_out)
        
class Hytana(torch.nn.Module):
    def __init__(self):
        super(Hytana, self).__init__()
        
    def forward(self, input):
        return HytanaFunction.apply(input)
        
class PHytana(torch.nn.Module):
    def __init__(self, num_parameters=1, init=(0.303, 0.632)):
        super(PHytana, self).__init__()
        self.num_parameters = num_parameters
        self.weight = torch.nn.Parameter(torch.Tensor([init] * self.num_parameters))
        
    def hytana(self, x, alpha, beta):
        return x/2 *(torch.tanh(alpha + beta * x))

    def forward(self, input):
        b,c,_,_ = input.size()
        if self.num_parameters > 1:
            assert c == self.num_parameters, 'The number of parameters should equal the number of channel'
            inps = torch.unbind(input, 1)
            output = list()
            for i in range(self.num_parameters):
                alpha, beta = self.weight[i]
                output.append(self.hytana(inps[i], alpha, beta))
            output = torch.stack(output, 1)
            return output
        alpha, beta = self.weight
        return self.hytana(input, alpha, beta)