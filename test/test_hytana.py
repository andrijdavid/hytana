import pytest
import torch
import torch.nn.functional as F
from torch.testing import assert_allclose

def hytana_forward_pt(x, alpha=0.303, beta=0.632):
    return x/2 *(1 + torch.tanh(alpha + (beta * x)))

class Hytana(torch.nn.Module):
    def forward(self, x, alpha=0.303, beta=0.632): 
        return hytana_forward_pt(x, alpha, beta)

def get_input_params():
    devs = ['cpu']
    if torch.cuda.is_available() and torch.cuda.device_count() > 0:
        devs += ['cuda:0'] # TODO: Allow other devices
    dev_types = [(dtype,device)
                 for dtype in [torch.float16,torch.float32,torch.float64]
                 for device in devs
                 # Basic ops not supported on CPU/Half, could test by converting but skip for now
                 if not (dtype==torch.float16 and torch.device(device).type == 'cpu')] 
    inputs = [(ndim,dtype,device)
              for (dtype,device) in dev_types
              for ndim in [1,2,3,4,8]]
    return inputs

@pytest.fixture(params=get_input_params())
def test_input(request):
    ndim,dtype,device = request.param
    sz = (2,) * (ndim-1) + (10,)
    if device == 'cpu' and dtype == torch.float16:
        return torch.randn(*sz).half() # No randn for half on CPU
    t = torch.randn(*sz, device=device, dtype=dtype)
    return t

def test_forward(test_input):
    from hytana_torch import hytana_forward
    res = hytana_forward(test_input)
    exp = hytana_forward_pt(test_input)
    assert_allclose(res, exp)

def get_grads(inp):
    y = hytana_forward_pt(inp)
    l = y.mean()
    grad_out, = torch.autograd.grad(l, y, retain_graph=True)
    exp, = torch.autograd.grad(y, inp, grad_out, retain_graph=True)
    return grad_out, exp

def test_backward(test_input):
    from hytana_torch import hytana_backward
    x = test_input.requires_grad_()
    grad_out,exp = get_grads(test_input)
    res = hytana_backward(test_input.detach(), grad_out)
    assert_allclose(res, exp)

def test_function(test_input):
    from hytana_torch import HytanaFunction
    x1,x2 = (test_input.clone().requires_grad_() for i in range(2))

    y1 = hytana_forward_pt(x1)
    l1 = y1.mean()
    exp, = torch.autograd.grad(l1, x1)
    y2 = HytanaFunction.apply(x2)
    l2 = y2.mean()
    res, = torch.autograd.grad(l2, x2)
    assert_allclose(res, exp)

def test_module(test_input):
    from hytana_torch import Hytana
    x1,x2 = (test_input.clone().requires_grad_() for i in range(2))

    m1 = Hytana()
    y1 = m1(x1)
    l1 = y1.mean()
    exp, = torch.autograd.grad(l1, x1)

    m2 = Hytana()
    y2 = m2(x2)
    l2 = y2.mean()
    res, = torch.autograd.grad(l2, x2)
    assert_allclose(res, exp)

def test_gradient():
    from hytana_torch import HytanaFunction
    inp = torch.randn(10, 10, dtype=torch.float64, requires_grad=True, device='cuda:0')
    assert torch.autograd.gradcheck(HytanaFunction.apply, inp)

def test_overlapping():
    '''Test handling of overlapping output tensors'''
    from hytana_torch import hytana_forward
    t = torch.randn(2, 10, device='cuda:0')
    t_o = t.as_strided((3,10), (5,1)) # Overlapping
    t_c = t_o.contiguous()             # Contiguous
    o_o = hytana_forward(t_o, torch.empty_like(t_o))
    o_c = hytana_forward(t_c, torch.empty_like(t_c))
    assert torch.equal(o_o, o_c)
