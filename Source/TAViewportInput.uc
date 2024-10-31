class TAViewportInput extends Input config(Input) transient;

function bool InputKey(int ControllerId, name Key, EInputEvent Event, float AmountDepressed = 1.f, bool bGamepad = FALSE)
{
	return TAViewportClient(self.Outer).InputKey(ControllerId, Key, Event, AmountDepressed, bGamepad);
}

DefaultProperties
{
	OnReceivedNativeInputKey=InputKey
}
