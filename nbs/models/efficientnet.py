
from geffnet.gen_efficientnet import _create_model
from geffnet.efficientnet_builder import decode_arch_def, round_channels, resolve_bn_args
from torch import nn

def efficientnet_b0(variant = 'efficientnet_b0', **kwargs):
    return efficientnet(variant, **kwargs)

def efficientnet(variant, pretrained=False, act_layer=nn.ReLU, channel_multiplier=1.0, depth_multiplier=1.0, **kwargs):
    # NOTE for train set drop_rate=0.2, drop_connect_rate=0.2
    arch_def = [
        ['ds_r1_k3_s1_e1_c16_se0.25'],
        ['ir_r2_k3_s2_e6_c24_se0.25'],
        ['ir_r2_k5_s2_e6_c40_se0.25'],
        ['ir_r3_k3_s2_e6_c80_se0.25'],
        ['ir_r3_k5_s1_e6_c112_se0.25'],
        ['ir_r4_k5_s2_e6_c192_se0.25'],
        ['ir_r1_k3_s1_e6_c320_se0.25'],
    ]
    model_kwargs = dict(
        block_args=decode_arch_def(arch_def, depth_multiplier),
        num_features=round_channels(1280, channel_multiplier, 8, None),
        stem_size=32,
        channel_multiplier=channel_multiplier,
        act_layer=act_layer,
        norm_kwargs=resolve_bn_args(kwargs),
        **kwargs,
    )
    model = _create_model(model_kwargs, variant, pretrained)
    return model