SocialRules={}
function SocialRules.visible(observer,subject)
    return observer.source~=subject.source and observer.bucket==subject.bucket and subject.share==true and observer.blips~='none' and (observer.blips~='group' or (observer.group~=nil and observer.group==subject.group))
end
function SocialRules.canInvite(sender,target,kind)
    return sender.source~=target.source and sender.bucket==target.bucket and target.invites~='none' and (kind=='group' or kind=='duel')
end
function SocialRules.inviteValid(invite,src,now) return invite and invite.target==src and now<invite.expires and not invite.consumed end
